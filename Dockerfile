FROM httpd:2.4

RUN apt update
RUN apt install -y vim
RUN apt install -y libcgi-pm-perl
RUN apt install -y libcarp-always-perl
RUN apt install -y libdata-dmp-perl

COPY app/cgi-bin /usr/local/apache2/cgi-bin
COPY app/htdocs /usr/local/apache2/htdocs

RUN chmod +x /usr/local/apache2/cgi-bin/*.pl
RUN chmod a+w /usr/local/apache2/cgi-bin/MTData/users
RUN chown -R www-data:www-data /usr/local/apache2/cgi-bin/MTData
RUN perl -pi -e 's/#LoadModule (?=cgid?_)/LoadModule /' /usr/local/apache2/conf/httpd.conf
RUN echo 'SetEnv PERL5LIB  /usr/local/apache2/cgi-bin' >> /usr/local/apache2/conf/httpd.conf
