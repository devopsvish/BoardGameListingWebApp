FROM adoptopenjdk/openjdk11
 
ENV APP_HOME /usr/src/app

COPY target/*.jar $APP_HOME/app.jar

WORKDIR $APP_HOME

EXPOSE 8080

CMD ["java", "-jar", "app.jar"]
