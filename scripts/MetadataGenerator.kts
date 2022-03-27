import java.io.FileWriter;
import java.lang.System;

fun getGemForId(id: Int): String{
    return when(id){
        0-> "Azure"
        1-> "Lapis"
        2-> "Saphirre"
        3-> "Emerald"
        4-> "Ruby"
        5-> "Diamond"
        6-> "Goblet"
        else -> ""
    }
}

fun getMetadataForId(id: Int, gemType: Int, isRedeemed: Boolean): String{
    var json = "{\"id\":\"${id}\",\"description\":\"${getGemForId(gemType)} #${id}is a token minted on purchase of a case." +
            " Collect all 6 tokens to be eligible to get the Goblet\"," +
            "\"external_url\":\"https://www.maltgraincane.com/\"," +
            "\"image\":\"ipfs://QmPAT6h5smsTX57PSvsB86zXUTgodzu8dchcV9AjhkvyUK/${id}.svg\"," +
            "\"name\":\"MultiGrain & Cane Whiskey ${getGemForId(gemType)}#${id}\"," +
            "\"attributes\":[{\"trait_type\": \"IsRedeemed\", \"value\": \"${isRedeemed}\"}]}"
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

fun generateMetadataNotRedeemed() {
    val dir = System.getProperty("user.dir").replace("scripts","Metadata-notredeemed")
    System.out.println("Working Directory = " + dir);
    for(i in 0..5){
        for (j in 1..50){
            //val fileName = java.lang.Integer.toHexString(i*100+j);
            var fileName = String.format("0x%064X", i*100+j);
            fileName = fileName.replace("0x","").lowercase()
            writeToFile(dir, getMetadataForId(j, i, false), fileName)
        }
    }
}

fun generateMetadataRedeemed() {
    val dir = System.getProperty("user.dir").replace("scripts","Metadata-redeemed")
    System.out.println("Working Directory = " + dir);
    for(i in 0..5){
        for (j in 1..50){
            //val fileName = java.lang.Integer.toHexString(i*100+j);
            var fileName = String.format("0x%064X", i*100+j);
            fileName = fileName.replace("0x","").lowercase()
            writeToFile(dir, getMetadataForId(j, i, true), fileName)
        }
    }
}

generateMetadataNotRedeemed()
generateMetadataRedeemed()