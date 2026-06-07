import click
from os import environ,path,remove
import shutil
from  time import perf_counter
import gigaam
import torch
import torchaudio
import noisereduce as nr
import tempfile
from pyannote.audio import Pipeline

from typing import Optional, List, Tuple
import numpy as np

in_folder='/app/in'
subfolder='transcribed'
WAVE_SAMPLE_RATE=16000
 


@click.command()
@click.option('--audio_file_path', required=True, help='audio file path')
@click.option('--model', default='v3_e2e_rnnt', help='model:v3_e2e_rnnt')
@click.option('--min_speakers', default=None, type=int, help='min_speakers')
@click.option('--max_speakers', default=None, type=int, help='max_speakers')
@click.option('--diarization', default=0, type=int, help='diarization')
@click.option('--requirements', default=0, type=int, help='Export requirements.in')
@click.option('--diarization_model', default='pyannote/speaker-diarization-community-1', help='diarization model')
@click.option('--noisereduce_rate', default=0.4, type=float, help='noisereduce_rate')


def transcribe_pipline(
    audio_file_path: str,
    model: str = 'v3_e2e_rnnt',
    min_speakers: int = None,
    max_speakers: int = None,
    diarization:int =0,
    requirements:int=0,
    diarization_model:str='pyannote/speaker-diarization-community-1',
    noisereduce_rate:float=0.4

):
    if requirements==1:
        shutil.copy('requirements.in', path.join(in_folder,"requirements.in"))
    start_time = perf_counter()
    hf_token = environ.get('hugging_token')
    
    try:
        audio_dict=load_audio((path.join(in_folder,audio_file_path)),noisereduce_rate)   
        transcribed_result = transcribe(audio_dict['temp_file_name'],model)

        if diarization==1:
            diar_result=diarization_pipe({"waveform": audio_dict["waveform"],
                                        "sample_rate": audio_dict["sample_rate"]},
                                        diarization_model,
                                        hf_token,
                                        min_speakers,
                                        max_speakers
                                        )
            result=merge_diar_transcribe(diar_result.speaker_diarization,transcribed_result.segments)
        else:
            result=transcribed_result.text    
        output_transform(result,audio_file_path)
    finally:
        # Гарантированное удаление временного WAV-файла для предотвращения утечки места на диске
        if path.exists(audio_dict['temp_file_name']):
            remove(audio_dict['temp_file_name'])        
    time_delta=perf_counter()-start_time
    print(f"Затрачено времени на {audio_file_path}: {int(time_delta//60)}min {int(time_delta%60)}s")

def transcribe(audio,model_name:str):
    model = gigaam.load_model(model_name)
    return model.transcribe_longform(audio, word_timestamps=True)

def load_audio(audio_path:str,noisereduce_rate:float=-1.0)->dict:
    waveform, sample_rate = torchaudio.load(audio_path)
    # GigaAM обычно ожидает 16000 Гц и моно-канал
    if sample_rate != WAVE_SAMPLE_RATE:  
        resampler = torchaudio.transforms.Resample(orig_freq=sample_rate, new_freq=WAVE_SAMPLE_RATE)
        waveform = resampler(waveform)
        sample_rate = WAVE_SAMPLE_RATE
    if waveform.shape[0] > 1:
        waveform = torch.mean(waveform, dim=0, keepdim=True)
        
    if noisereduce_rate>0:       
        # 3. Интеграция noisereduce
        # Переводим тензор PyTorch в массив NumPy для библиотеки noisereduce
        waveform_numpy = waveform.numpy()

        # Применяем шумоподавление. 
        # stationary=True идеально подходит для удаления постоянного гула, шипения и шума вентиляторов.
        cleaned_numpy = nr.reduce_noise(
            y=waveform_numpy, 
            sr=sample_rate, 
            stationary=True,
            prop_decrease=noisereduce_rate  # Уменьшите до 0.85, если голоса станут звучать "роботизировано"
        )

        # Возвращаем массив NumPy обратно в тензор PyTorch
        waveform = torch.from_numpy(cleaned_numpy)

    
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as temp_file:
        temp_filename = temp_file.name
        # torchaudio умеет писать напрямую в путь файла
        torchaudio.save(temp_filename, waveform, sample_rate)
    return {'temp_file_name':temp_filename,"waveform": waveform, "sample_rate": sample_rate}

def diarization_pipe(
    audio,
    diarization_model:str,
    token: str,
    min_speakers: int=None,
    max_speakers: int =None,
) -> list:
    
    kwargs = {"token": token}
    if min_speakers is not None:
        kwargs["min_speakers"] = min_speakers
    if max_speakers is not None:
        kwargs["max_speakers"] = max_speakers    
    
    pyannote_pipeline = Pipeline.from_pretrained(diarization_model,**kwargs)
    return pyannote_pipeline(audio)


def merge_diar_transcribe(diar_result:list,transcript_segments:list):
    transcript_segments_transformed=[{'start':seg.start,
                                      'end':seg.end,
                                      'words':[{'text':word.text,'start':word.start,'end':word.end} 
                                               for word in seg.words]} for seg in transcript_segments
                                    ]
    merged_diar= assign_word_speakers(diar_result,transcript_segments_transformed)
    prev_speaker=merged_diar[0]['words'][0]['speaker']
    text_final=f'{prev_speaker}:'
    for row in merged_diar:
        for word in row['words']:
            if prev_speaker == word.get('speaker', prev_speaker):
                text_final = f'{text_final} {word["text"]}'
            else:
                prev_speaker = word['speaker']
                text_final = f'{text_final}\n{prev_speaker}:{word["text"]}'
    return text_final



class IntervalTree:
    """
    Simple interval tree for fast overlap queries using sorted array + binary search.

    Uses O(n) space and provides O(log n) query time instead of O(n) linear scan.
    This achieves ~228x speedup for speaker assignment in long-form content.
    """

    def __init__(self, intervals: List[Tuple[float, float, str]]):
        """
        Initialize the interval tree with diarization segments.

        Args:
            intervals: List of (start, end, speaker) tuples
        """
        if not intervals:
            self.starts = np.array([])
            self.ends = np.array([])
            self.speakers: List[str] = []
            return

        # Sort intervals by start time for binary search
        sorted_intervals = sorted(intervals, key=lambda x: x[0])
        self.starts = np.array([i[0] for i in sorted_intervals], dtype=np.float64)
        self.ends = np.array([i[1] for i in sorted_intervals], dtype=np.float64)
        self.speakers = [i[2] for i in sorted_intervals]

    def query(self, start: float, end: float) -> List[Tuple[str, float]]:
        """
        Find all intervals that overlap with [start, end] and compute intersection.

        Args:
            start: Query interval start time
            end: Query interval end time

        Returns:
            List of (speaker, intersection_duration) tuples for overlapping segments
        """
        if len(self.starts) == 0:
            return []

        # Binary search to find candidate intervals
        # Only intervals with start < end could overlap
        right_idx = np.searchsorted(self.starts, end, side='left')
        if right_idx == 0:
            return []

        # Check candidates for actual overlap
        candidates = slice(0, right_idx)
        overlaps = (self.starts[candidates] < end) & (self.ends[candidates] > start)

        results = []
        for idx in np.where(overlaps)[0]:
            intersection = min(self.ends[idx], end) - max(self.starts[idx], start)
            if intersection > 0:
                results.append((self.speakers[idx], intersection))
        return results

    def find_nearest(self, time: float) -> Optional[str]:
        """
        Find the speaker of the nearest segment to a given time point.

        Args:
            time: Time point to find nearest segment for

        Returns:
            Speaker ID of nearest segment, or None if no segments exist
        """
        if len(self.starts) == 0:
            return None

        # Calculate midpoints of all segments
        mids = (self.starts + self.ends) / 2
        nearest_idx = np.argmin(np.abs(mids - time))
        return self.speakers[nearest_idx]

def assign_word_speakers(
    diarize_df,
    transcript_segments,
    fill_nearest: bool = False,
) :
    """
    Assign speakers to words and segments in the transcript.

    Uses an interval tree for O(log n) overlap queries instead of O(n) linear scan,
    achieving ~228x speedup for long-form content (3+ hour podcasts).

    Args:
        diarize_df: Diarization dataframe from DiarizationPipeline
        transcript_result: Transcription result to augment with speaker labels
        speaker_embeddings: Optional dictionary mapping speaker IDs to embedding vectors
        fill_nearest: If True, assign speakers even when there's no direct time overlap

    Returns:
        Updated transcript_result with speaker assignments and optionally embeddings
    """


    # Build interval tree from diarization segments for O(log n) queries
    intervals = [
        (row[0].start, row[0].end, row[1])
        for  row in diarize_df
    ]
    tree = IntervalTree(intervals)
    
    for seg in transcript_segments:
        seg_start = seg.get('start', 0.0)
        seg_end = seg.get('end', 0.0)

        # Query overlapping segments using interval tree
        overlaps = tree.query(seg_start, seg_end)

        if overlaps:
            # Sum intersection durations per speaker and pick the dominant one
            speaker_intersections: dict[str, float] = {}
            for speaker, intersection in overlaps:
                speaker_intersections[speaker] = speaker_intersections.get(speaker, 0.0) + intersection
            seg['speaker'] = max(speaker_intersections.items(), key=lambda x: x[1])[0]
        elif fill_nearest:
            # Find nearest segment if no overlap
            seg_mid = (seg_start + seg_end) / 2
            nearest_speaker = tree.find_nearest(seg_mid)
            if nearest_speaker:
                seg['speaker'] = nearest_speaker

        # Assign speaker to words
        if 'words' in seg:
            for word in seg['words']:

                if 'start' not in word:
                    continue

                word_start = word['start']
                word_end = word.get('end', word_start)

                word_overlaps = tree.query(word_start, word_end)

                if word_overlaps:
                    speaker_intersections = {}
                    for speaker, intersection in word_overlaps:
                        speaker_intersections[speaker] = speaker_intersections.get(speaker, 0.0) + intersection
                    word['speaker'] = max(speaker_intersections.items(), key=lambda x: x[1])[0]
                elif fill_nearest:
                    word_mid = (word_start + word_end) / 2
                    nearest_speaker = tree.find_nearest(word_mid)
                    if nearest_speaker:
                        word['speaker'] = nearest_speaker


    return transcript_segments

def output_transform(result:str,original_file_path:str)->None:  
    filename = path.basename(original_file_path)
    name_only = path.splitext(filename)[0]
    file_path=path.join(in_folder,subfolder,f"transcribed_{name_only}.txt")

    with open(file_path, "w") as f:
        f.write(result)
    return None
if __name__ == "__main__":
    transcribe_pipline()
    


