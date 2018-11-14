Requires Python 3.7.0 or above. I personally like (pyenv)[https://github.com/pyenv/pyenv#installation] for managing versions.

## Setup
``` python
pyenv install 3.7.0
pyenv virtualenv 3.7.0 matkonot
pyenv activate matkonot
pip install -r requirements
```

## Run
``` python
python main.py
```

This will get the party started and launch some parallel scrapers. You can follow their progress with `tail -f log`.
A cool `matkonot.db` file will appear at the directory once the fetching has ended, which should be placed under `../server/` before launching the server.
