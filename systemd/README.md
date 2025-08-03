### Systemd configuration

We use the forever program to restart the servers
after a version change, so that
server-triggered updates can be performed
without administrative privileges (which are required for systemctl).
We still use systemd to ensure that the systems are started at boot-time,
so we do want to update the service files here when we change a version,
even though they will not be used until the next boot...

WHO IS GOING TO REMIND SOMEONE TO DO THAT???

### First time setup


  ### Link the file to /lib/systemd/system

A convenience script link\_service.sh is provided.

  # Service installation commands (run as root):
  # ln -s /home/jbmull/lab2-test1-page.service /lib/systemd/system
  # systemctl daemon-reload
  # systemctl enable lab2-test1-page.service
  # systemctl start lab2-test1-page.service


ExecStartPre=

