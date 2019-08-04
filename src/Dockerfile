FROM python:3.6-alpine
ENV PYTHONBUFFERED 1
RUN mkdir /code
WORKDIR /code
ADD . /code
RUN apk update \
    && apk add --virtual build-deps gcc python3-dev musl-dev build-base linux-headers pcre-dev \
    && apk add --no-cache mariadb-dev

RUN pip install -r requirements.txt
RUN apk del build-deps
