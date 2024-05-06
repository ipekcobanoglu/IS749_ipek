package tr.edu.metu.sm703;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

@Controller
public class HomeController {

    @Get
    public Map<String, Object> index() {
        Map map = new HashMap();
        map.put("statusCode", 200);
        map.put("body", "{\"message\", \"Hello AWS World\"}");
        return map;
    }
}