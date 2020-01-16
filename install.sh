#!/bin/bash
{
    set -e
    SUDO=''
    if [ "$(id -u)" != "0" ]; then
      SUDO='sudo'
      echo "This script requires superuser access."
      echo "You will be prompted for your password by sudo."
      # clear any previous sudo permission
      sudo -k
    fi


    # run inside sudo
    $SUDO bash <<SCRIPT
touch /usr/local/bin/gsu
echo "#!/usr/bin/env alusus.dbg
import \"Srl/Console.alusus\";
import \"Srl/Memory.alusus\";
import \"Srl/String.alusus\";
import \"Srl/Net.alusus\";
import \"Apm.alusus\";
Apm.importFile(\"xlmnxp/Json\")

use Srl;
func start(argCount: Int, argv: ptr[array[ptr[array[Char]]]]) {
    if argCount < 3 {
        Console.print(\"Usage: %s <snap>\n\", argv~cnt(1));
        return;
    }
    
    def curlHandle: ptr[Net.Curl] = Net.CurlEasy.init();
    def resultCount: ptr[Int];
    def responseCode: ptr[Int];

    def content: Net._Content;
    content.data = 0
    content.size = 0
    
    def headers: ptr[Net.CurlSlist] = null;
    headers = Net.CurlSlist.append(headers, \"Snap-Device-Series: 16\");

    def url: String = \"http://api.snapcraft.io/v2/snaps/info/\";
    url += argv~cnt(2);

    Net.CurlEasy.setOpt(curlHandle, Net.CurlOpt.URL, url.buf);
    Net.CurlEasy.setOpt(curlHandle, Net.CurlOpt.USERAGENT, \"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36\");
    Net.CurlEasy.setOpt(curlHandle, Net.CurlOpt.HTTPGET, true);
    Net.CurlEasy.setOpt(curlHandle, Net.CurlOpt.HTTPHEADER, headers);
    Net.CurlEasy.setOpt(curlHandle, Net.CurlOpt.SSL_VERIFYPEER, false);
    Net.CurlEasy.setOpt(curlHandle, Net.CurlOpt.FOLLOWLOCATION, true);

    def response: ptr[array[Char]] = Net.Curl.exec(curlHandle, resultCount, responseCode)~cast[ptr[array[Char]]];

    if response != 0 {
        def json: Json = response;
        if json.keysArray(0) == \"error-list\" {
            Console.print(\"%s: %s\n\", json.getObject(\"error-list\").getObject(0).getString(\"code\").replace(\"-\", \" \").toUpperCase().buf, json.getObject(\"error-list\").getObject(0).getString(\"message\").buf);
        } else {
            Console.print(\"%s\n\", json.getObject(\"channel-map\").getObject(0).getObject(\"download\").getString(\"url\").buf);
        }
    } else {
        Console.print(\"ERROR: cannot send request.\n\");
        Console.print(\"RESPONSE CODE: %d\n\", responseCode~cnt)
    }
    Net.CurlEasy.cleanup(curlHandle);
} start(Process.argCount, Process.args)" > /usr/local/bin/gsu
chmod +x /usr/local/bin/gsu

echo "GSU installed to /usr/local/bin/gsu"
SCRIPT
}