A project to build a Docker image of Silverpeas for testing purpose during the developments. For doing, a dataset is provided, among them the dump of the Silverpeas database `silverpeas-db.dump` matching the initial contributions in the `src/data` directory. The dump is for a PostgreSQL RDBMS.

The docker image includes Silverpeas and some of its dependencies like OpenOffice used for document format conversion or SWFTools/PDF2JSON for the conversion of content to PDF. The database isn't included in the image so you have to run it in another container and link it with your silverpeas-run container. Before running a silverpeas-run container, you have also to restore the initial state of the Silverpeas data (which contains a ready-to-use set of data) from the `silverpeas-db.dump` backup.

In order to update Silverpeas in the running container, the `.m2/repository` folder in your user account on the host is mounted onto the container so any artifacts resulting from a build on the host can be fetched by the installer of Silverpeas in the container. So, it is important the identifier and group identifier of the user in the container (user `silveruser`) matches yours corresponding identifiers on the host.

## Build a Docker image of silverpeas-run

To build a Docker image for, for example, Silverpeas 6.3 with Wildfly 26.1.2 and Java 11:
```
$ ./build.sh -w 26.1.2 -j 11 -s 6.3
```

By default, the Dockerfile expects your user and group identifiers on the host to be both `1000`. In the case your identifiers actually differ, for example with a user identifier of `1026` and a group identifier of `65536`, you can specify them in the command line:
```
$ ./build.sh -w 26.1.2 -j 11 -s 6.3 -u 1026 -g 65536 
```

The two above commands will build a Docker image tagged as `latest`. To specify a different tag or version, `6.3-build1` for example:
```
$ ./build.sh -w 26.1.2 -j 11 -s 6.3 -u 1026 -g 65536  -v 6.3-build1
```

For any others options, please just do:
```
$ ./build.sh -h
```

## Run a container of silverpeas-run

Before running a container of _silverpeas-run_, a container with the database for Silverpeas has to be spawn before. Indeed, the _silverpeas-run_ container is linked to the container in which the database for Silverpeas is running. (Don't forget to restore the Silverpeas database with the dump `silverpeas-db.dump` in the `src/` directory of this project.)

To run a container from an existing Docker image of _silverpeas-run_, for example from the version `6.3-build1`, and with as database a container named `silverpeas-database`:
```
$ ./run.sh -d silverpeas-database -c my-silverpeas -i 6.3-build1
```

This will launch the _silverpeas-run_ container with as name `my-silverpeas` and a shell connection on the running container is opened for you.

By default, in the container, any installation and update of Silverpeas explode the web archive into the `/home/silveruser/webapp` directory. This folder can be mounted on the host for, for example, updating by hand the web resources like javascripts or JSPs. For example, to mount it on the `$HOME/silverpeas/6.3.x/webapp` folder of the host:
```
$ ./run.sh -d silverpeas-database -c my-silverpeas -i 6.3-build1 -m $HOME/silverpeas/6.3.x/webapp
```

To run the container in a Docker network other the default one, for example in an existing network named `silverpeas-net`:
```
$ ./run.sh -n silverpeas-net -d silverpeas-database -c my-silverpeas -i 6.3-build1
```

For any others options, please just do:
```
$ ./run.sh -h
```