# Cyber Range Lite: Challenge Template
If you would like to develop CTF challenges that are
compatible with Cyber Range Lite, then you have found
the right place!

Here we present the file structure and content of a simple
web "challenge".

```sh
$ tree .
.
├── app
│   ├── app.py
│   ├── bootup.sh
│   ├── flag.sh
│   └── index.html
├── docker-compose.yml
├── Dockerfile
├── README.md # you are here!
└── testrun.sh
```

The [Dockerfile](Dockerfile) specifies what image the
challenge should be built on (in this case python).
It also sets a default flag value as an environment variable.
Dependencies are installed, files from the app directory
are copied over to the image and specified as the working
directory. The Dockerfile concludes with running the
bootup script (located in the app directory) which is
where the magic happens!

```Dockerfile
FROM python:3.9

ENV FLAG=flag{fake_flag}
RUN pip install flask
COPY app app
WORKDIR /app

ENTRYPOINT ["./bootup.sh"]
```

As a rule, we have decided to set the flag in run-time instead of
build-time. This means that the same image can be used by multiple users,
who will have unique flags!  We have also separated the setting of the flag
into two steps (bootup.sh + flag.sh) so that we can remove traces which
could leak the flag if the user gains foothold in the container (which might
be intended).

The [bootup script](app/bootup.sh) should only do 3 things.  Run the flag
script, remove the flag script, and start the container service.
```sh
#!/bin/bash
./flag.sh
rm flag.sh
python app.py
```

The [flag script](app/flag.sh) contains information about
where the flag is located, which is why it is removed after execution.
In this simple example, the script is replacing a placeholder
in the index.html file. The environment variable is then unset.
```sh
#!/bin/bash
sed -i "s/flag-location/$FLAG/g" index.html
unset $FLAG
```

The [docker compose](docker-compose.yml) file has two sections:
**x-challenges** and **services**. The former containing information for CTFd
and is ignored by docker (because the tag starts with **x-**).  The latter is
specifying the container to be run, with its build context, flag, and ports.
The image repo can be specified (e.g., docker.cs.kau.se) which
will try to pull the image before building.  The flag can be dynamically
created by CRL when specifying "crl{DYNAMIC}", but the flag can also be set in
a static way.  The ports have two important properties. The first number (1337)
is arbitrary, but must match the port-id in x-challenges. This is to map the
CTFd challenge connection-info to the exposed container port in a
jeopardy-style CTF.  When running a black-box cyber range, this value is
replaced and connection-info is not posted to CTFd.  The second number (80) is
the service port running on the container.  In this example, the port is
specified by Flask in [app.py](app/app.py).
```yml
x-challenges:
    FLAG: # must match the env. variable in services
        name: "Challenge Name"
        description: "Challenge description"
        connection-info: 'http://{HOST}:{PORT}'
        port-id: '1337' # must match the host port in services

services:
    app:
        build: .
        image: docker.cs.kau.se/csma/cyber-range/challenges/kauotic/crl-template
        environment:
            FLAG: 'crl{DYNAMIC}' # or 'flag{static}'
        ports:
            - '1337:80/tcp'
```

