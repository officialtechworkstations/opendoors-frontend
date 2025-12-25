import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis_auth/auth_io.dart';

import 'Api/config.dart';

class FirebaseAccesstoken {
  static String firebaseMessageScope =
      "https://www.googleapis.com/auth/firebase.messaging";

  Future<String> getAccessToken() async {
    final credentials = ServiceAccountCredentials.fromJson({
      "type": "service_account",
      "project_id": dotenv.env['PROJECT_ID'],
      "private_key_id": dotenv.env['PRIVATE_KEY_ID'],
      "private_key": dotenv.env['PRIVATE_KEY'],
      "client_email":
          "firebase-adminsdk-fbsvc@open-doors-app-2025f.iam.gserviceaccount.com",
      "client_id": "117913723346881847375",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":
          "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40open-doors-app-2025f.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    });

    final client =
        await clientViaServiceAccount(credentials, [firebaseMessageScope]);

    final accessToken = client.credentials.accessToken.data;
    Config.firebaseKey = accessToken;
    print("+++++++++++++++++:---- ${Config.firebaseKey}");
    return accessToken;
  }
  // Future<String> getAccessToken() async {
  //   final credentials = ServiceAccountCredentials.fromJson({
  //     "type": "service_account",
  //     "project_id": "open-doors-app-2025f", // dotenv.env['PROJECT_ID'],
  //     "private_key_id":
  //         "9cfb60546d6d35b6fdac42fac52b99690ac70db6", // dotenv.env['PRIVATE_KEY_ID'],
  //     "private_key":
  //         "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQC9NUi5TK+byeWy\niuUXIYC8BCDPg5cYPwMMMwjirvPi43Ed1oqMDlAmXSmmAfYYFc9lkcFmz7NTszRk\n1vDkj3APa9UZX0ucn1+ItSSEAfCKrO1Q/Pq6P+FxDvEpT8r7F9V0ZWC7Z3++W/Tk\ngnP4LQ9Z+zpIuan3/W9XkrNk20Z6RDc4mho1e87KroBW4cp07kxfIIMuyWSK++aT\nxUtlLDtasAAkv3NVzQ8LReW35dqs29UoEtVyiurPECSgqKI/rqtOkneeSDuwzDgx\nQgZRay1P22jX0LIzHsHLEKG8f70dchAQxLokmBy/vG1rrQuQRJ9/IOtDJn4uIkub\nD+hSFWixAgMBAAECggEACrnwlitWG/Da3WpTs8ypwv7rlUK9LW9fuYX9z6FiIM9g\nDvRQr8FH+JojeE54KG65bo/6yjH61UM9idHy9MzPlNrkySbGiencZ/WiTPwx1MrE\n5r3QwP+fb4y3Te5AxZyuSduixj0HLZWCUUoL+lp476hMaj8MTGDJD8qN8lPJWmOs\nAMkPeHI88QMPIKuK4J6rela9MAIqJUYLOHJSo8fPBKEz1Agxuq3ygFwXrZ9sJJWA\nBtMu0hmAaTfrklRIwlizbApXvp5UkKoqOwpvgA65V6MIdeuETkmRR1ugLO/JPORr\nqpdrABFIIAgBZ0Ulhf73UxY6f3elTcA2eiMFSayC2QKBgQDfjLrqHiw+GQ/Hpyba\nj7wgQce8aMlvjMlDknN9lziUHcDK8upSoNx5FtUYQrBsImxzDhtLGADA/+0PdVp2\nPaUrqc2p9XyKg7WVlnwDKwj7DAdm+RCKlW2fEZ1TELvIubVwRqYxE+SegANU7kDn\nnHX6yi3lhjzQ4eODkr+hkQT+YwKBgQDYrGVNel5OjVSp0mlXJdAXvdTV7TpI6Q3m\nZ7Il8rclk7zgZ3AhqDzlQ8bWb1hQLUGLDcGupXwSYNKMfjq2Ru6YoKaXqh9luhtZ\nziE0FV80uHqn0PivpTAtjCQxL/ihhUsf1aqTY+rVHWZngOAqWcA4br6L5C2QFA2d\nScK99J4u2wKBgE8zeemGZSBfGrMeqmpW8EzxYUWETpHB7HCPS3GciQQZAnwk0hYS\nPep8x2TAA+dbztZ4kfzp9SJryd5nMnSf5IvyrhXgDo64mTX1SdyJe7YODfVSmqSu\nylbIE9ghHpbADONJdIoAxUfOjN+jRcWJLld7GAWwqI1M6qFr9Y7VZVKHAoGAGi5i\no0UJBjbfpxGMtwITrfq7MApVQ6AdlNys0xcL+FdsuDTngLmiehWBfkHACxgc1l+Y\nKrFGV7YpWt6Z25KgnAK1fpgI6TLewTA+JNv8QBOWhpaiph6wvqAzc1oXkfTYSgV4\ncgzdwFioGhOhgpyLtIX1MlQlCUbTClFyXZ+kSYcCgYAEoaiYAUxJKETXGSiPiB87\nchmEaCWwkw7egJxxcUD0xnQ5FO3VJMVJOcsvApE1XVCufiidhRvV4TUAvf6WYTCd\nQWqD9sP3vd18WKvk7ceCjGNjIOYQ83ldYnwwCkb3XCmR7RZqx0BS8bun6Bgl3bAd\nJ+fKYqaSBDcJNDEVotSOxg==\n-----END PRIVATE KEY-----\n", //dotenv.env['PRIVATE_KEY'],
  //     "client_email":
  //         "firebase-adminsdk-fbsvc@open-doors-app-2025f.iam.gserviceaccount.com",
  //     "client_id": "117913723346881847375",
  //     "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  //     "token_uri": "https://oauth2.googleapis.com/token",
  //     "auth_provider_x509_cert_url":
  //         "https://www.googleapis.com/oauth2/v1/certs",
  //     "client_x509_cert_url":
  //         "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40open-doors-app-2025f.iam.gserviceaccount.com",
  //     "universe_domain": "googleapis.com"
  //   });

  //   final client =
  //       await clientViaServiceAccount(credentials, [firebaseMessageScope]);

  //   final accessToken = client.credentials.accessToken.data;
  //   Config.firebaseKey = accessToken;
  //   print("+++++++++++++++++:---- ${Config.firebaseKey}");
  //   return accessToken;
  // }
}
