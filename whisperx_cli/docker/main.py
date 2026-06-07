import click
from os import environ,path
import shutil
import whisperx
from whisperx.diarize import DiarizationPipeline

from  time import perf_counter
import logging
logging.getLogger("whisperx").setLevel(logging.ERROR)

in_folder='/app/in'
subfolder='transcribed'

@click.command()
@click.option('--audio_file_path', help='audio file path') #@click.option('--name', prompt='Your name', help='The person to greet.')
@click.option('--requirements', default=0, help='Export requirements.in')
@click.option('--compute', default='fast', help='compute fast|accurate')
@click.option('--language', default='ru', help='Voice language')
@click.option('--model', default='small', help='model:small|medium|large')
@click.option('--diarization', default=0, help='diarization')
@click.option('--min_speakers', default=None, help='min_speakers')
@click.option('--max_speakers', default=None, help='max_speakers')
def transcribe_pipline(
    audio_file_path: str,
    compute: str = 'fast',
    language='ru',
    model: str = 'small',
    diarization: int = 0,
    min_speakers: int = None,
    max_speakers: int = None,
    requirements:int=0

):
    if requirements==1:
        shutil.copy('requirements.in', path.join(in_folder,"requirements.in"))
    start_time = perf_counter()
    model_save_path, hf_token = (
        environ.get('model_save_path'),
        environ.get('hugging_token'),
    )
    model_params = get_model_params(compute=compute)
    print(f'model:{model}')
    model = whisperx.load_model(
        model,
        compute_type=model_params['compute_type'],
        language=language,
        device=model_params['device'],
        download_root=model_save_path,
    )
    audio = whisperx.load_audio(path.join(in_folder,audio_file_path) )
    result = model.transcribe(audio, batch_size=model_params['batch_size'])
    # 2. Транскрибация завершена (whisperx)
    if diarization==1:
        result = diarization_pipe(
            audio,
            transcribe_result=result,
            device=model_params['device'],
            token=hf_token,
            min_speakers=min_speakers,
            max_speakers=max_speakers,
        )
    output_transform(result,audio_file_path)
    time_delta=perf_counter()-start_time
    print(f"Затрачено времени на {audio_file_path}: {int(time_delta//60)}min {int(time_delta%60)}s")

def get_model_params(compute: str) -> dict:
    if False:
        pass
    else:
        print('🐌 Running on CPU...')
        device = 'cpu'
        batch_size = 1
        if compute == 'fast':
            compute_type = 'int8'
        else:
            compute_type = 'int8' #'float32' упадет на CPU
    return {
        'device': device,
        'batch_size': batch_size,
        'compute_type': compute_type,
    }

def diarization_pipe(
    audio,
    transcribe_result: list,
    device: str,
    token: str,
    min_speakers: int,
    max_speakers=None,
) -> list:
    print('⏳ Этап 2: Точное выравнивание временных меток...')
    model_a, metadata = whisperx.load_align_model(
        language_code=transcribe_result['language'], device=device
    )
    result = whisperx.align(
        transcribe_result['segments'],
        model_a,
        metadata,
        audio,
        device,
        return_char_alignments=False,
    )
    
    # 3. Диаризация (Pyannote)
    print('⏳ Этап 3: Разделение спикеров (Pyannote)...')
    diarize_model = DiarizationPipeline(token=token, device=device)

    # Опционально: если вы точно знаете число спикеров, добавьте: min_speakers=2, max_speakers=2
    if min_speakers is not None and max_speakers is not None:
        diarize_segments = diarize_model(
            audio, min_speakers=min_speakers, max_speakers=max_speakers
        )
    else:
        diarize_segments = diarize_model(audio)

    # 4. Сопоставление текста и спикеров
    print('⏳ Этап 4: Объединение текста и голосов...')
    diar_result = whisperx.assign_word_speakers(diarize_segments, result)
    return diar_result

def output_transform(result:str,original_file_path:str)->None:  
    filename = path.basename(original_file_path)
    name_only = path.splitext(filename)[0]
    file_path=path.join(in_folder,subfolder,f"transcribed_{name_only}.txt")
    """
    with open(file_path, "w") as f:
        dump(result['segments'], f,indent=json_indent)
    print(f'File saved:{file_path}') 
    """
    text_res,prev_speaker=None,''
    for segment in result["segments"]:
        speaker = segment.get("speaker", "UNKNOWN_SPEAKER")
        
        if text_res is not None:
            text_res=text_res+'\n'
        else:
            text_res=''
        if speaker!=prev_speaker:
            prev_speaker=speaker
            text_res=text_res+f"{speaker}:{segment['text']}"
        else:
            text_res=text_res+segment['text']
    with open(file_path, "w") as f:
        f.write(text_res)
    return None
if __name__ == "__main__":
    transcribe_pipline()
    


