package com.system.irtqaa

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.google.firebase.auth.FirebaseAuth

private enum class AntiquesSection(val title: String) {
    MARKET("السوق المباشر"),
    AUCTIONS("المزادات"),
    EXCHANGES("التبادل"),
    COLLECTION("مجموعتي"),
    HISTORY("سجل الصفقات")
}

/**
 * Player-to-player Baghdad antiques market.
 * All ownership, wallet, escrow and settlement changes are performed by
 * authenticated Firebase callable functions; this screen never writes them.
 */
@Composable
fun SystemAntiquesMarketplaceScreen(
    modifier: Modifier = Modifier
) {
    val repository = remember { FirebaseArtifactMarketplaceRepository() }
    val currentUid = FirebaseAuth.getInstance().currentUser?.uid.orEmpty()
    var section by remember { mutableStateOf(AntiquesSection.MARKET) }
    var wallet by remember { mutableStateOf<SystemMarketplaceWallet?>(null) }
    var artifacts by remember { mutableStateOf<List<SystemOwnedArtifact>>(emptyList()) }
    var listings by remember { mutableStateOf<List<SystemArtifactListing>>(emptyList()) }
    var auctions by remember { mutableStateOf<List<SystemArtifactAuction>>(emptyList()) }
    var exchanges by remember { mutableStateOf<Map<String, List<Map<String, Any?>>>>(emptyMap()) }
    var transactions by remember { mutableStateOf<List<Map<String, Any?>>>(emptyList()) }
    var selectedArtifactId by remember { mutableStateOf("") }
    var priceText by remember { mutableStateOf("") }
    var bidText by remember { mutableStateOf("") }
    var recipientId by remember { mutableStateOf("") }
    var requestedArtifactId by remember { mutableStateOf("") }
    var busy by remember { mutableStateOf(false) }
    var message by remember { mutableStateOf<String?>(null) }

    val background = Color(0xFF101827)
    val panel = Color(0xFF1B2940)
    val gold = Color(0xFFFFCF70)
    val cyan = Color(0xFF63D9E8)

    fun refresh() {
        if (currentUid.isBlank()) {
            message = "سجّل الدخول حتى تستخدم سوق اللاعبين."
            return
        }
        repository.loadWallet { result ->
            result.onSuccess { wallet = it }
                .onFailure { message = "تعذر تحميل المحفظة: ${it.message}" }
        }
        repository.loadOwnedArtifacts { result ->
            result.onSuccess { artifacts = it }
                .onFailure { message = "تعذر تحميل القطع المملوكة: ${it.message}" }
        }
        repository.browseListings(callback = { result ->
            result.onSuccess { listings = it }
                .onFailure { message = "تعذر تحميل عروض السوق: ${it.message}" }
        })
        repository.browseAuctions { result ->
            result.onSuccess { auctions = it }
                .onFailure { message = "تعذر تحميل المزادات: ${it.message}" }
        }
        repository.loadMyExchangeOffers { result ->
            result.onSuccess { exchanges = it }
                .onFailure { message = "تعذر تحميل طلبات التبادل: ${it.message}" }
        }
        repository.loadTransactionHistory { result ->
            result.onSuccess { transactions = it }
                .onFailure { message = "تعذر تحميل سجل الصفقات: ${it.message}" }
        }
    }

    LaunchedEffect(currentUid) { refresh() }

    fun perform(action: ((Result<Unit>) -> Unit) -> Unit, success: String) {
        if (busy) return
        busy = true
        message = null
        action { result ->
            busy = false
            result.onSuccess {
                message = success
                refresh()
            }.onFailure {
                message = it.message ?: "لم تكتمل العملية."
            }
        }
    }

    Column(
        modifier = modifier.fillMaxSize(),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Card(
            colors = CardDefaults.cardColors(containerColor = panel),
            shape = RoundedCornerShape(20.dp)
        ) {
            Column(Modifier.fillMaxWidth().padding(16.dp)) {
                Text("برج التحف والآثار", color = gold, fontSize = 25.sp, fontWeight = FontWeight.Black)
                Text("سوق عالمي للتجارة المباشرة بين اللاعبين", color = Color.LightGray)
                Spacer(Modifier.height(12.dp))
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Column {
                        Text("رصيد SYSTEM", color = Color.LightGray)
                        Text("${wallet?.balance ?: "—"}", color = Color.White, fontSize = 22.sp, fontWeight = FontWeight.Bold)
                    }
                    Column(horizontalAlignment = Alignment.End) {
                        Text("المتاح للتداول", color = Color.LightGray)
                        Text("${wallet?.availableBalance ?: "—"}", color = cyan, fontSize = 22.sp, fontWeight = FontWeight.Bold)
                        Text("محجوز: ${wallet?.reservedBalance ?: 0}", color = Color.LightGray, fontSize = 12.sp)
                    }
                }
                Spacer(Modifier.height(8.dp))
                OutlinedButton(onClick = { refresh() }, enabled = !busy) { Text("تحديث بيانات السوق") }
            }
        }

        ScrollableTabRow(
            selectedTabIndex = section.ordinal,
            containerColor = background,
            contentColor = gold,
            edgePadding = 0.dp
        ) {
            AntiquesSection.entries.forEachIndexed { index, item ->
                Tab(
                    selected = section == item,
                    onClick = { section = item },
                    text = { Text(item.title, maxLines = 1) }
                )
            }
        }

        if (busy) LinearProgressIndicator(Modifier.fillMaxWidth(), color = gold)
        message?.let {
            Card(colors = CardDefaults.cardColors(containerColor = panel)) {
                Text(it, Modifier.padding(12.dp), color = if (it.contains("تعذر") || it.contains("لم ")) Color(0xFFFFB4AB) else cyan)
            }
        }

        when (section) {
            AntiquesSection.MARKET -> {
                LazyColumn(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    if (listings.isEmpty()) item {
                        Text("لا توجد عروض بيع حالياً. يمكنك عرض قطعة من مجموعتك.", color = Color.LightGray)
                    }
                    items(listings, key = { it.listingId }) { listing ->
                        Card(colors = CardDefaults.cardColors(containerColor = panel)) {
                            Column(Modifier.fillMaxWidth().padding(14.dp)) {
                                Text(listing.name, color = Color.White, fontWeight = FontWeight.Bold, fontSize = 18.sp)
                                Text("${listing.civilization} • ${listing.rarity} • ${listing.condition}", color = cyan)
                                Text("البائع: ${listing.sellerName}", color = Color.LightGray)
                                Text("${listing.price} SYSTEM", color = gold, fontSize = 20.sp, fontWeight = FontWeight.Bold)
                                if (listing.sellerId == currentUid) {
                                    OutlinedButton(
                                        onClick = {
                                            perform(
                                                action = { callback -> repository.cancelListing(listing.listingId, callback) },
                                                success = "أُلغي عرضك وأُعيدت القطعة إلى مجموعتك."
                                            )
                                        },
                                        enabled = !busy
                                    ) { Text("إلغاء عرضي") }
                                } else {
                                    Button(
                                        onClick = {
                                            perform(
                                                action = { callback -> repository.purchaseListing(listing.listingId) { result ->
                                                    callback(result.map { Unit })
                                                } },
                                                success = "اكتملت عملية الشراء وانتقلت الملكية إلى حسابك."
                                            )
                                        },
                                        enabled = !busy,
                                        colors = ButtonDefaults.buttonColors(containerColor = gold, contentColor = Color.Black)
                                    ) { Text("شراء القطعة") }
                                }
                            }
                        }
                    }
                }
            }
            AntiquesSection.AUCTIONS -> {
                LazyColumn(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    if (auctions.isEmpty()) item { Text("لا توجد مزادات نشطة حالياً.", color = Color.LightGray) }
                    items(auctions, key = { it.auctionId }) { auction ->
                        Card(colors = CardDefaults.cardColors(containerColor = panel)) {
                            Column(Modifier.fillMaxWidth().padding(14.dp)) {
                                Text(auction.name, color = Color.White, fontWeight = FontWeight.Bold, fontSize = 18.sp)
                                Text("${auction.civilization} • ${auction.rarity}", color = cyan)
                                Text("أعلى مزايدة: ${auction.highestBid} SYSTEM", color = gold)
                                Text("عدد المزايدات: ${auction.bidCount}", color = Color.LightGray)
                                OutlinedTextField(
                                    value = bidText,
                                    onValueChange = { bidText = it.filter(Char::isDigit).take(12) },
                                    label = { Text("مبلغ المزايدة") },
                                    singleLine = true,
                                    enabled = !busy
                                )
                                if (auction.sellerId != currentUid) {
                                    Button(
                                        onClick = {
                                            val amount = bidText.toLongOrNull()
                                            if (amount == null || amount <= auction.highestBid) {
                                                message = "اكتب مزايدة أعلى من السعر الحالي."
                                            } else perform(
                                                action = { callback -> repository.placeAuctionBid(auction.auctionId, amount, callback) },
                                                success = "تم تسجيل المزايدة وحجز رصيدها."
                                            )
                                        },
                                        enabled = !busy
                                    ) { Text("تأكيد المزايدة") }
                                } else if (auction.bidCount == 0) {
                                    OutlinedButton(
                                        onClick = {
                                            perform(
                                                action = { callback -> repository.cancelAuction(auction.auctionId, callback) },
                                                success = "أُلغي المزاد وأُعيدت القطعة إلى مجموعتك."
                                            )
                                        },
                                        enabled = !busy
                                    ) { Text("إلغاء المزاد") }
                                }
                                if (auction.endsAt > 0L && auction.endsAt <= System.currentTimeMillis()) {
                                    OutlinedButton(
                                        onClick = {
                                            perform(
                                                action = { callback -> repository.settleAuction(auction.auctionId, callback) },
                                                success = "تمت تسوية المزاد وتحديث الملكية والمحافظ."
                                            )
                                        },
                                        enabled = !busy
                                    ) { Text("تسوية المزاد المنتهي") }
                                }
                            }
                        }
                    }
                }
            }
            AntiquesSection.EXCHANGES -> {
                LazyColumn(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    item {
                        Card(colors = CardDefaults.cardColors(containerColor = panel)) {
                            Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                Text("إنشاء تبادل مباشر", color = gold, fontWeight = FontWeight.Bold, fontSize = 18.sp)
                                Text("اختر قطعة من مجموعتك، ثم أدخل معرّف اللاعب ومعرّف القطعة التي تريدها.", color = Color.LightGray)
                                OutlinedTextField(value = selectedArtifactId, onValueChange = { selectedArtifactId = it }, label = { Text("معرّف قطعتك المعروضة") }, singleLine = true)
                                OutlinedTextField(value = recipientId, onValueChange = { recipientId = it.trim().take(128) }, label = { Text("معرّف اللاعب المستلم") }, singleLine = true)
                                OutlinedTextField(value = requestedArtifactId, onValueChange = { requestedArtifactId = it.trim().take(128) }, label = { Text("معرّف القطعة المطلوبة") }, singleLine = true)
                                Button(
                                    onClick = {
                                        if (selectedArtifactId.isBlank() || recipientId.isBlank() || requestedArtifactId.isBlank()) {
                                            message = "أكمل جميع معرّفات التبادل."
                                        } else {
                                            busy = true
                                            repository.createExchangeOffer(recipientId, selectedArtifactId, requestedArtifactId) { result ->
                                                busy = false
                                                result.onSuccess {
                                                    message = "أُرسل عرض التبادل وحُجزت قطعتك."
                                                    refresh()
                                                }.onFailure { message = it.message ?: "تعذر إرسال العرض." }
                                            }
                                        }
                                    },
                                    enabled = !busy
                                ) { Text("إرسال عرض التبادل") }
                                Text("قطعك المتاحة:", color = cyan, fontWeight = FontWeight.Bold)
                                artifacts.forEach { artifact ->
                                    Text(
                                        "اختيار: ${artifact.name} • ${artifact.artifactId}",
                                        color = Color.White,
                                        modifier = Modifier.fillMaxWidth().clickable { selectedArtifactId = artifact.artifactId }.padding(vertical = 5.dp)
                                    )
                                }
                            }
                        }
                    }
                    items(exchanges["received"].orEmpty(), key = { it["exchangeId"]?.toString().orEmpty() }) { offer ->
                        val id = offer["exchangeId"]?.toString().orEmpty()
                        Card(colors = CardDefaults.cardColors(containerColor = panel)) {
                            Column(Modifier.padding(12.dp)) {
                                Text("عرض تبادل وارد", color = gold, fontWeight = FontWeight.Bold)
                                Text("القطعة المعروضة: ${offer["offeredArtifactId"] ?: "—"}", color = Color.White)
                                Text("المطلوبة منك: ${offer["requestedArtifactId"] ?: "—"}", color = Color.LightGray)
                                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                    Button(onClick = { perform({ cb -> repository.acceptExchangeOffer(id) { cb(it) } }, "اكتمل التبادل وانتقلت الملكيتان.") }, enabled = !busy) { Text("قبول") }
                                    OutlinedButton(onClick = { perform({ cb -> repository.closeExchangeOffer(id, "decline") { cb(it) } }, "تم رفض عرض التبادل.") }, enabled = !busy) { Text("رفض") }
                                }
                            }
                        }
                    }
                    items(exchanges["sent"].orEmpty(), key = { "sent_" + (it["exchangeId"]?.toString().orEmpty()) }) { offer ->
                        val id = offer["exchangeId"]?.toString().orEmpty()
                        Card(colors = CardDefaults.cardColors(containerColor = panel)) {
                            Column(Modifier.padding(12.dp)) {
                                Text("عرضك المرسل", color = gold, fontWeight = FontWeight.Bold)
                                Text("الحالة: ${offer["status"] ?: "قيد الانتظار"}", color = Color.White)
                                OutlinedButton(onClick = { perform({ cb -> repository.closeExchangeOffer(id, "cancel") { cb(it) } }, "أُلغي العرض وأُعيدت القطعة إلى مجموعتك.") }, enabled = !busy) { Text("إلغاء العرض") }
                            }
                        }
                    }
                }
            }
            AntiquesSection.HISTORY -> {
                LazyColumn(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    if (transactions.isEmpty()) item {
                        Text("لا توجد صفقات مسجلة في حسابك بعد.", color = Color.LightGray)
                    }
                    items(transactions, key = { it["transactionId"]?.toString().orEmpty() }) { record ->
                        val isBuyer = record["buyerId"]?.toString() == currentUid
                        Card(colors = CardDefaults.cardColors(containerColor = panel)) {
                            Column(Modifier.fillMaxWidth().padding(14.dp)) {
                                Text(
                                    if (isBuyer) "عملية شراء" else "عملية بيع",
                                    color = gold,
                                    fontWeight = FontWeight.Bold
                                )
                                Text("القطعة: ${record["artifactId"] ?: (record["artifactIds"] ?: "—")}", color = Color.White)
                                Text("الطرف الآخر: ${if (isBuyer) record["sellerName"] ?: "لاعب" else record["buyerName"] ?: "لاعب"}", color = cyan)
                                Text("القيمة: ${record["price"] ?: 0} ${record["currency"] ?: "SYSTEM"}", color = Color.White)
                                Text("رقم العملية: ${record["transactionId"] ?: "—"}", color = Color.LightGray, fontSize = 11.sp)
                            }
                        }
                    }
                }
            }
            AntiquesSection.COLLECTION -> {
                LazyColumn(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    if (artifacts.isEmpty()) item { Text("لا توجد قطع أثرية قابلة للتداول في مجموعتك حالياً.", color = Color.LightGray) }
                    items(artifacts, key = { it.artifactId }) { artifact ->
                        Card(colors = CardDefaults.cardColors(containerColor = panel)) {
                            Column(Modifier.padding(14.dp)) {
                                Text(artifact.name, color = Color.White, fontWeight = FontWeight.Bold, fontSize = 18.sp)
                                Text("${artifact.civilization} • ${artifact.rarity}", color = cyan)
                                Text("الحالة: ${artifact.condition} • الأصالة: ${artifact.authenticity}", color = Color.LightGray)
                                if (artifact.provenanceSummary.isNotBlank()) Text(artifact.provenanceSummary, color = Color.LightGray, fontSize = 12.sp)
                                OutlinedButton(onClick = { selectedArtifactId = artifact.artifactId }) {
                                    Text(if (selectedArtifactId == artifact.artifactId) "تم اختيار القطعة" else "اختيار القطعة")
                                }
                            }
                        }
                    }
                    item {
                        Card(colors = CardDefaults.cardColors(containerColor = panel)) {
                            Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                Text("عرض القطعة للبيع بسعر ثابت", color = gold, fontWeight = FontWeight.Bold)
                                Text("القطعة المختارة: ${selectedArtifactId.ifBlank { "لم يتم الاختيار" }}", color = Color.LightGray)
                                OutlinedTextField(
                                    value = priceText,
                                    onValueChange = { priceText = it.filter(Char::isDigit).take(12) },
                                    label = { Text("السعر بعملة SYSTEM") },
                                    singleLine = true,
                                    enabled = !busy
                                )
                                Button(
                                    onClick = {
                                        val price = priceText.toLongOrNull()
                                        if (selectedArtifactId.isBlank() || price == null || price <= 0L) {
                                            message = "اختر قطعة واكتب سعراً صحيحاً."
                                        } else {
                                            busy = true
                                            repository.createListing(selectedArtifactId, price) { result ->
                                                busy = false
                                                result.onSuccess {
                                                    message = "عُرضت القطعة في السوق وحُجزت حتى البيع أو الإلغاء."
                                                    selectedArtifactId = ""
                                                    priceText = ""
                                                    refresh()
                                                }.onFailure { message = it.message ?: "تعذر إنشاء العرض." }
                                            }
                                        }
                                    },
                                    enabled = !busy
                                ) { Text("عرض للبيع") }
                                Button(
                                    onClick = {
                                        val start = priceText.toLongOrNull()
                                        if (selectedArtifactId.isBlank() || start == null || start <= 0L) {
                                            message = "اختر قطعة واكتب سعر بداية صحيحاً."
                                        } else {
                                            busy = true
                                            repository.createAuction(selectedArtifactId, start) { result ->
                                                busy = false
                                                result.onSuccess {
                                                    message = "بدأ المزاد وحُجزت القطعة."
                                                    selectedArtifactId = ""
                                                    priceText = ""
                                                    refresh()
                                                }.onFailure { message = it.message ?: "تعذر إنشاء المزاد." }
                                            }
                                        }
                                    },
                                    enabled = !busy
                                ) { Text("إنشاء مزاد بسعر البداية نفسه") }
                            }
                        }
                    }
                }
            }
        }
    }
}
