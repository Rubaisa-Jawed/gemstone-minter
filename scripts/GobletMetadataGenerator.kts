import java.io.FileWriter;
import java.lang.System;

fun getMetadataForId(id: Int, year: Int): String {
    var json = "{\"id\":\"${id}\"," +
            "\"description\":\"Exclusive mintable Goblets collection for customers who have 6 GEMSTONES to redeem. You can mint replica goblets for each year, from 2022 to 2025\"," +
            "\"external_url\":\"https://maltgrainwhiskey.com\"," +
            "\"seller_fee_basis_points\":1000," +
            "\"image\":\"ipfs://QmcYPCU1Hy3VYLoSnkxxcxgW4B4CRwJaz3bxymkcXQNwWC/${year}.png\"," +
            "\"name\":\"Goblet #${id}\"," +
            "\"attributes\":[" +
            "{\"display_type\": \"number\"," +
            "\"trait_type\": \"Limited Edition\"," +
            "\"value\": 1, \"max_value\": 50}," +
            "{\"trait_type\": \"Year\"," +
            "\"value\": \"${year}\"" +
            "}," +
            "{\"trait_type\": \"Type\"," +
            "\"value\": \"Goblet\"" +
            "}" +
            "]}"
    return json
}

fun writeToFile(dir: String, message: String, id: String) {
    FileWriter("${dir}/${id}.json").use { writer ->
        try {
            writer.write(message)
        }
        catch (ex: Exception) {
            ex.printStackTrace()
        }
    }
}

fun generateMetadata() {
    val dir = System.getProperty("user.dir").replace("scripts","Metadata-goblet");
    System.out.println("Working Directory = " + dir);
    for(year in 2022..2024){
        for (j in 1..50){
            var fileName = "${j}_${year}";
            writeToFile(dir, getMetadataForId(j,year), fileName.toString())
        }
    }
}

generateMetadata()
