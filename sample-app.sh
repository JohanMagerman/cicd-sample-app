#!/bin/bash
set -euo pipefail

mkdir tempdir
mkdir tempdir/templates
mkdir tempdir/static

cp sample_app.py tempdir/.
cp -r templates/* tempdir/templates/.
cp -r static/* tempdir/static/.

# python:3-slim (~44 MB compressed) instead of python (~420 MB): the lab router
# limits internet traffic to 1 Mbit/s, so the full image takes about an hour to
# pull on every host that builds it. Flask needs nothing from the full image.
cat > tempdir/Dockerfile << _EOF_
FROM python:3-slim
RUN pip install flask
COPY  ./static /home/myapp/static/
COPY  ./templates /home/myapp/templates/
COPY  sample_app.py /home/myapp/
EXPOSE 5050
CMD python /home/myapp/sample_app.py
_EOF_

cd tempdir || exit
docker build -t sampleapp .
docker run -t -d -p 5050:5050 --name samplerunning sampleapp
docker ps -a 
