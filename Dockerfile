FROM python:3.9

ENV FLAG=flag{fake_flag}
RUN pip install flask
COPY app app
WORKDIR /app

ENTRYPOINT ["./bootup.sh"]
