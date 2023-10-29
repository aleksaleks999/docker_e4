FROM python:3.10.1-alpine

WORKDIR /opt/
RUN cd /opt/ && pip3 install --upgrade pip && pip3 install django gunicorn sqlparse

RUN apk add postgresql postgresql-contrib nginx openrc
COPY default.conf /etc/nginx/http.d/

RUN mkdir /run/postgresql
RUN chown postgres:postgres /run/postgresql/
RUN su - postgres -c "initdb -D /var/lib/postgresql/data"
COPY script.sh /root/
RUN chmod +x /root/script.sh
RUN /root/script.sh
RUN /root/script.sh && su - postgres -c "psql -c 'CREATE DATABASE django;'" && su - postgres -c "psql -c 'CREATE USER pguser WITH PASSWORD '\''pgpassword'\'';'" && su - postgres -c "psql -c 'ALTER DATABASE django OWNER TO pguser;'"

RUN pip3 install psycopg2-binary
RUN django-admin startproject mysite .
COPY settings.py ./mysite/
RUN /root/script.sh && python3 manage.py migrate
RUN /root/script.sh && python3 manage.py shell -c "from django.contrib.auth.models import User; User.objects.create_superuser('admin', 'admin@example.com', 'adminpass')"
RUN mkdir -p /run/openrc/softlevel && touch /run/openrc/softlevel
RUN python manage.py collectstatic
RUN rc-update add nginx default
ENTRYPOINT /root/script.sh && gunicorn --bind 0.0.0.0:8000 mysite.wsgi






