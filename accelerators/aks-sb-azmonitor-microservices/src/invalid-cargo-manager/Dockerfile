FROM mcr.microsoft.com/mirror/docker/library/python:3.10-buster
WORKDIR /code
COPY ./requirements.txt /code/requirements.txt

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && python -m pip install --upgrade pip \
    && apt-get -y install --no-install-recommends cmake 

RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt

COPY ./src/service /code/service

CMD ["python", "/code/service/app.py", "--host", "0.0.0.0", "--port", "3100", "--proxy-headers"]
