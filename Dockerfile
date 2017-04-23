FROM gong023/node-coffee:latest
WORKDIR /var
RUN git clone https://github.com/gong023/my-hubot-process.git
WORKDIR /var/my-hubot-process
RUN npm install
COPY run.sh /var/my-hubot-process/run.sh
CMD ["run.sh"]
