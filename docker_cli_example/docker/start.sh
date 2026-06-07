
if [ -f "requirements.in" ]; then
    echo "File requirements.in exists."
else
    pip-compile --output-file requirements.in requirements.txt
fi

python -m uvicorn backend.main:app --host 0.0.0.0 --port 81