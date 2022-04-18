import java.io.FileWriter;
import java.lang.System;

fun getGemForId(id: Int): String{
    return when(id){
        0-> "Amethyst"
        1-> "Sapphire"
        2-> "Emerald"
        3-> "Citrine"
        4-> "Amber"
        5-> "Ruby"
        else -> ""
    }
}

fun getWebsiteLinkForId(id: Int): String{
    return when(id){
        0-> "www.maltgraincane.com/bottles/008B"
        1-> "www.maltgraincane.com/bottles/010B"
        2-> "www.maltgraincane.com/bottles/011B"
        3-> "www.maltgraincane.com/bottles/009B"
        4-> "www.maltgraincane.com/bottles/012B"
        5-> "www.maltgraincane.com/bottles/013B"
        else -> ""
    }
}

fun getDescriptionForId(id: Int): String{
    return when(id){
        0-> "An Amethyst gemstone that only exists on the Ethereum blockchain. " +
                "A commemorative token for the purchase of Malt, Grain & Cane's Curated Range bottlings (Year 2). " +
                "Upon closer inspection of this gemstone, a Powerful rush of emotions flow through you, leaving you with a bad mixture of melancholy, terrible longing, and nostalgia for a nearly-forgotten someone. " +
                "The temptation is there, but you resist the Powerful urge to reach back out to them."
        1-> "A Sapphire gemstone that only exists on the Ethereum blockchain. " +
                "A commemorative token for the purchase of Malt, Grain & Cane's Curated Range bottlings (Year 2). " +
                "Upon closer inspection of this gemstone, you suddenly feel as if you are floating down a waterbody, with the delicate scent of peonies surrounding & embracing the Space around you. You feel raindrops fall across your face, as your eyes gently close. " +
                "You start to feel the Space around you gradually expand, as your body gently drifts with the flow, into the great Unknown."
        2-> "An Emerald gemstone that only exists on the Ethereum blockchain. " +
                "A commemorative token for the purchase of Malt, Grain & Cane's Curated Range bottlings (Year 2). " +
                "Upon closer inspection of this gemstone, you suddenly feel a thrilling rush of energising force pulsating within you. You are reminded of your younger, youthful days, as if, for a brief moment in Time, you are youthful as you once were. " +
                "\"What a wonderful Time to be alive...\""
        3-> "A Citrine gemstone that only exists on the Ethereum blockchain. " +
                "A commemorative token for the purchase of Malt, Grain & Cane's Curated Range bottlings (Year 2). " +
                "Upon closer inspection of this gemstone, your Mind starts to experience brief, yet, lucid moments of clarity. You're start to see things in a broader & wholistic perspective. In the back of your Mind, you barely see a male figure, dressed up in a bright yellow jumpsuit, flailing a pair of nunchucks... " +
                "\"Bruce.. is that.. you..?\""
        4-> "An Amber stone that only exists on the Ethereum blockchain. " +
                "A commemorative token for the purchase of Malt, Grain & Cane's Curated Range bottlings (Year 2). " +
                "Upon closer inspection of this fossilised resin, you are suddenly transported to Japan, during the the early 1980s.\n" +
                "You are driving in your Daihatsu, along the coast of Shizuoka Prefecture, on a cool summer evening. With the windows down, you look across the Suruga Bay.\n" +
                "The Japanese Citypop hit-song, \"Remember Me\" by Step, is playing on the car radio. Your Soul is at peace, as you smile, while you continue your driving journey into the night."
        5-> "A Ruby gemstone that only exists on the Ethereum blockchain. " +
                "A commemorative token for the purchase of Malt, Grain & Cane's Curated Range bottlings (Year 2). " +
                "Upon closer inspection of this gemstone, you start to notice numerous cracks developing across the gemstone. It seems like something is emerging out of this gemstone. A sudden burst of brilliant energy roars through the cracks, as a maiden emerges. You blink & stumble, as you're bewildered by this abnormally. " +
                "Your vision instantly snaps back into focus, as the Ruby gem is once made whole again, and you start to question to yourself; \"Was that a Dream, or was that Reality...?\"\n" +
                "You pick yourself up, gather your belongings, and continue your journey forward."
        else -> ""
    }
}

fun getMetadataForId(id: Int, gemType: Int, isRedeemed: Boolean): String {
    var json = "{\"id\":\"${id}\",\"description\":\"${getDescriptionForId(gemType)}\"," +
            "\"external_url\":\"${getWebsiteLinkForId(gemType)}\"," +
            "\"seller_fee_basis_points\":1000," +
            "\"image\":\"ipfs://QmUEBb6FbtizW9iHBMvnfNrX3xhELSa4SyBktEEy4J2cBD/${id}.png\"," +
            "\"name\":\"${getGemForId(gemType)} #${id}\"," +
            "\"attributes\":[" +
            "{\"trait_type\": \"IsRedeemed\", \"value\": \"${isRedeemed}\"}," +
            "{\"display_type\": \"number\"," +
            "\"trait_type\": \"Limited Edition\"," +
            "\"value\": 1, \"max_value\": 50}," +
            "{\"trait_type\": \"Year\"," +
            "\"value\": \"2022\"" +
            "}," +
            "{\"trait_type\": \"Type\"," +
            "\"value\": \"Gemstone\"" +
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

fun generateMetadataNotRedeemed() {
    val dir = System.getProperty("user.dir").replace("scripts","Metadata-notredeemed")
    System.out.println("Working Directory = " + dir);
    for(i in 0..5){
        for (j in 1..50){
            //val fileName = java.lang.Integer.toHexString(i*100+j);
            //var fileName = String.format("0x%064X", i*100+j);
            //val fileName = fileName.replace("0x","").lowercase()
            val fileName= i*50+j;
            writeToFile(dir, getMetadataForId(i*50+j, i, false), fileName.toString())
        }
    }
}

fun generateMetadataRedeemed() {
    val dir = System.getProperty("user.dir").replace("scripts","Metadata-redeemed")
    System.out.println("Working Directory = " + dir);
    for(i in 0..5){
        for (j in 1..50){
            //val fileName = java.lang.Integer.toHexString(i*100+j);
            var fileName = i*50+j;
            writeToFile(dir, getMetadataForId(i*50+j, i, true), fileName.toString())
        }
    }
}

generateMetadataNotRedeemed()
generateMetadataRedeemed()
