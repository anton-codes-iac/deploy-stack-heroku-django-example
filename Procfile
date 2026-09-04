web: gunicorn core.wsgi -b 0.0.0.0:8000 --access-logfile - --log-file -
worker: celery -A core worker -l info