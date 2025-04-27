const upload_url = '/api/upload';

function message_update(message_type, message) {
  let _element = document.getElementById('flash-message');
  _element.className = '';
  _element.classList.add('flash-message');
  _element.classList.add(message_type);
  document.getElementById('flash-message-text').textContent = message;
  _element.style.display = 'block';
}

function alert_close() {
  document.getElementById('flash-message').style.display = 'none';
}

function get_input_values() {
  let fields_id = ['tentacles', 'name'];
  return Object.fromEntries(
    fields_id.map((field_id) => [
      field_id,
      document.getElementById(field_id).value,
    ])
  );
}

async function FileUpload() {
  let input_files = document.getElementById('image-file');
  let input_values = get_input_values(),
    formData = new FormData(),
    file = input_files.files[0],
    _status;

  formData.append('file', file);
  formData.append('upload_params', JSON.stringify(input_values));
  //const ctrl = new AbortController()    // timeout setTimeout(() => ctrl.abort(), 5000);
  try {
    let r = await fetch(upload_url, {
      method: 'POST',
      body: formData, //,signal: ctrl.signal
    });
    _status = r.headers.get('status');
    if (_status === 'success') {
      let response = await r.blob(); //.json();//text()
      let filename = r.headers.get('filename'),
        url = window.URL.createObjectURL(response),
        a = document.createElement('a');
      a.style.display = 'none';
      a.href = url;
      // the filename you want
      a.download = filename;
      document.body.appendChild(a);
      a.click();
      a.remove();
    } else {
      let response = await r.json();
      message_update(_status, response['message']);
    }
    // window.URL.revokeObjectURL(url);
  } catch (e) {
    message_update('error', e);
  }
}
