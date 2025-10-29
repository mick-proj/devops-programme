FROM ubuntu:22.04

RUN apt update && apt upgrade -y

RUN apt install python3 -y
RUN apt install pip -y

COPY ./requirements.txt ./
RUN pip install -r requirements.txt

COPY ./app ./

EXPOSE 3000

RUN useradd flask
USER flask
CMD ["python3", "app.py"]
