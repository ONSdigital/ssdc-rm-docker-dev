import java.net.*;

public class HealthcheckRequest {
  public static void main(String[] args) throws Exception {
    if (args.length != 1) {
      throw new IllegalArgumentException("Expected exactly one argument, the URL to GET");
    }
    URL url = new URL(args[0]);
    HttpURLConnection con = (HttpURLConnection) url.openConnection();
    con.setRequestMethod("GET");
    int status = con.getResponseCode();
    if (status != 200) {
      System.exit(1);
    }
  }
}
