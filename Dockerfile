FROM python:3.9

WORKDIR /app
ADD . /app/
EXPOSE 8000
RUN pip install -r requirements.txt --no-cache-dir
RUN python manage.py makemigrations && python manage.py migrate
ENTRYPOINT [ "python" ]
CMD ["manage.py", "runserver", "0.0.0.0:8000"]