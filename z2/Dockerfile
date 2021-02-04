#
FROM ubuntu:latest

LABEL maintainer="marek.a.matys@accenture.com"

RUN apt-get update && apt-get upgrade -y

RUN apt-get install python3 -y

EXPOSE 8080

ADD my_logging_server.py .

CMD ["python3","my_logging_server.py"]
