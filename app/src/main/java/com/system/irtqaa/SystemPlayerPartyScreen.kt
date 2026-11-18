package com.system.irtqaa

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun SystemPlayerPartyScreen(account: SystemFirebaseAccount) {
    val repository = remember { FirebasePlayerPartyRepository() }
    val signedIn = repository.isSignedIn() && account.userId != "system_guest_local"
    var partyName by remember { mutableStateOf("") }
    var targetPlayerId by remember { mutableStateOf("") }
    var parties by remember { mutableStateOf<List<SystemPlayerParty>>(emptyList()) }
    var invites by remember { mutableStateOf<List<SystemPlayerPartyInvite>>(emptyList()) }
    var missions by remember { mutableStateOf<List<SystemHunterGuildMission>>(emptyList()) }
    var assignments by remember { mutableStateOf<List<SystemHunterGuildMissionAssignment>>(emptyList()) }
    var status by remember { mutableStateOf("إدارة فرق اللاعبين الحقيقيين") }
    var busy by remember { mutableStateOf(false) }

    fun refresh() {
        if (!signedIn) return
        busy = true
        repository.loadMyParties { result ->
            result.onSuccess { parties = it }
                .onFailure { status = it.message ?: "تعذر تحميل الفرق." }
            busy = false
        }
        repository.loadMyInvites { result ->
            result.onSuccess { invites = it }
                .onFailure { status = it.message ?: "تعذر تحميل الدعوات." }
        }
        repository.loadAvailableHunterGuildMissions { result ->
            result.onSuccess { missions = it }
                .onFailure { status = it.message ?: "تعذر تحميل مهمات XSX." }
        }
        repository.loadMyHunterGuildMissionAssignments { result ->
            result.onSuccess { assignments = it }
                .onFailure { status = it.message ?: "تعذر تحميل سجل تسجيلات المهمات." }
        }
    }

    LaunchedEffect(account.userId) { refresh() }

    Column(
        modifier = Modifier.fillMaxSize().padding(14.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Text("SYSTEM • PLAYER PARTIES", color = Color(0xFF55DDF0), fontSize = 13.sp, fontWeight = FontWeight.Bold)
        Text("فرق اللاعبين", color = Color(0xFFFFC857), fontSize = 27.sp, fontWeight = FontWeight.Black)
        Text("الفريق مجموعة تعاونية من حسابات لاعبين حقيقية، وليس نقابة أو مجموعة NPC.", color = Color.LightGray)
        Text(status, color = Color(0xFF55DDF0), fontSize = 13.sp)

        if (!signedIn) {
            Card(colors = CardDefaults.cardColors(containerColor = Color(0xFF25243A))) {
                Column(Modifier.padding(14.dp)) {
                    Text("يلزم تسجيل الدخول بحساب SYSTEM حقيقي لاستخدام الفرق والدعوات.", color = Color.White)
                    Text("وضع الضيف لا ينشئ هوية لاعب أونلاين ولا يستطيع الانضمام إلى الفرق.", color = Color.LightGray)
                }
            }
        } else {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(
                    value = partyName,
                    onValueChange = { partyName = it.take(32) },
                    label = { Text("اسم الفريق") },
                    modifier = Modifier.weight(1f),
                    singleLine = true
                )
                Button(
                    enabled = !busy && partyName.isNotBlank(),
                    onClick = {
                        busy = true
                        repository.createParty(partyName) { result ->
                            result.onSuccess {
                                partyName = ""
                                status = "تم إنشاء الفريق على الخادم."
                                refresh()
                            }.onFailure { status = it.message ?: "تعذر إنشاء الفريق." }
                            busy = false
                        }
                    }
                ) { Text("إنشاء") }
            }

            Text("دعواتك الواردة (${invites.size})", color = Color(0xFFFFC857), fontWeight = FontWeight.Bold)
            if (invites.isEmpty()) {
                Text("لا توجد دعوات معلقة.", color = Color.LightGray, fontSize = 13.sp)
            } else {
                LazyColumn(modifier = Modifier.height(150.dp), verticalArrangement = Arrangement.spacedBy(7.dp)) {
                    items(invites, key = { it.inviteId }) { invite ->
                        Card(colors = CardDefaults.cardColors(containerColor = Color(0xFF202B40))) {
                            Column(Modifier.fillMaxWidth().padding(10.dp)) {
                                Text(invite.partyName, color = Color.White, fontWeight = FontWeight.Bold)
                                Text("دعوة من: ${invite.fromName}", color = Color.LightGray, fontSize = 12.sp)
                                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                    TextButton(onClick = {
                                        repository.respondToInvite(invite.inviteId, true) { result ->
                                            result.onSuccess { status = "تم قبول الدعوة."; refresh() }
                                                .onFailure { status = it.message ?: "تعذر قبول الدعوة." }
                                        }
                                    }) { Text("قبول") }
                                    TextButton(onClick = {
                                        repository.respondToInvite(invite.inviteId, false) { result ->
                                            result.onSuccess { status = "تم رفض الدعوة."; refresh() }
                                                .onFailure { status = it.message ?: "تعذر رفض الدعوة." }
                                        }
                                    }) { Text("رفض") }
                                }
                            }
                        }
                    }
                }
            }

            Row {
                Text("فرقك (${parties.size})", color = Color(0xFFFFC857), fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
                TextButton(onClick = { refresh() }, enabled = !busy) { Text("تحديث") }
            }
            if (parties.isEmpty()) {
                Text("لم تنضم إلى فريق بعد. أنشئ فريقاً أو اقبل دعوة.", color = Color.LightGray, fontSize = 13.sp)
            } else {
                LazyColumn(verticalArrangement = Arrangement.spacedBy(9.dp)) {
                    items(parties, key = { it.partyId }) { party ->
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            colors = CardDefaults.cardColors(containerColor = Color(0xFF18253A)),
                            shape = RoundedCornerShape(14.dp)
                        ) {
                            Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(7.dp)) {
                                Text(party.name, color = Color.White, fontSize = 18.sp, fontWeight = FontWeight.Bold)
                                Text(
                                    if (party.leaderId == account.userId) "أنت قائد الفريق" else "قائد الفريق: ${party.leaderId.take(10)}…",
                                    color = Color(0xFF55DDF0), fontSize = 12.sp
                                )
                                Text("الأعضاء: ${party.memberIds.size} / ${party.maxMembers}", color = Color.LightGray)
                                Text("معرّف الفريق: ${party.partyId}", color = Color.Gray, fontSize = 10.sp)
                                if (party.leaderId == account.userId && party.memberIds.size < party.maxMembers) {
                                    OutlinedTextField(
                                        value = targetPlayerId,
                                        onValueChange = { targetPlayerId = it.trim().take(128) },
                                        label = { Text("معرّف حساب اللاعب المراد دعوته") },
                                        modifier = Modifier.fillMaxWidth(), singleLine = true
                                    )
                                    Button(
                                        enabled = targetPlayerId.isNotBlank(),
                                        onClick = {
                                            repository.invitePlayer(party.partyId, targetPlayerId) { result ->
                                                result.onSuccess {
                                                    targetPlayerId = ""
                                                    status = "أُرسلت الدعوة إلى حساب اللاعب."
                                                }.onFailure { status = it.message ?: "تعذر إرسال الدعوة." }
                                            }
                                        }
                                    ) { Text("إرسال دعوة") }
                                }
                                TextButton(onClick = {
                                    repository.leaveParty(party.partyId) { result ->
                                        result.onSuccess {
                                            status = if (it == "disbanded") "تم إنهاء الفريق بعد مغادرة آخر عضو." else "غادرت الفريق."
                                            refresh()
                                        }.onFailure { status = it.message ?: "تعذرت مغادرة الفريق." }
                                    }
                                }) { Text("مغادرة الفريق") }
                            }
                        }
                    }
                }
            }

            Text("لوحة مهمات نقابة الصيادين XSX", color = Color(0xFFFFC857), fontSize = 21.sp, fontWeight = FontWeight.Bold)
            Text(
                "يسجّل قائد الفريق فريقه الحقيقي فقط. تُحفظ قائمة الأعضاء عند التسجيل ولا يمكن استبدالها من واجهة العميل.",
                color = Color.LightGray,
                fontSize = 12.sp
            )
            if (missions.isEmpty()) {
                Text("لا توجد مهمات مفتوحة منشورة حالياً من إدارة XSX.", color = Color.LightGray, fontSize = 13.sp)
            } else {
                LazyColumn(
                    modifier = Modifier.height(330.dp),
                    verticalArrangement = Arrangement.spacedBy(9.dp)
                ) {
                    items(missions, key = { it.missionId }) { mission ->
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            colors = CardDefaults.cardColors(containerColor = Color(0xFF202B40)),
                            shape = RoundedCornerShape(14.dp)
                        ) {
                            Column(
                                Modifier.fillMaxWidth().padding(12.dp),
                                verticalArrangement = Arrangement.spacedBy(7.dp)
                            ) {
                                Text(mission.title, color = Color.White, fontSize = 17.sp, fontWeight = FontWeight.Bold)
                                Text(mission.description, color = Color.LightGray, fontSize = 12.sp)
                                Text(
                                    "العالم: ${when (mission.worldId) {
                                        "modern" -> "العالم الحديث"
                                        "historical" -> "عالم الحضارات"
                                        "fantasy" -> "عالم الفانتازيا"
                                        "greed" -> "جزيرة الطمع"
                                        else -> mission.worldId
                                    }}  •  الرتبة: ${mission.rank}",
                                    color = Color(0xFF55DDF0),
                                    fontSize = 12.sp
                                )
                                Text(
                                    "حجم الفريق: ${mission.minMembers}-${mission.maxMembers} • الفرق المسجلة: ${mission.activeTeamCount}/${mission.maxTeams}",
                                    color = Color.LightGray,
                                    fontSize = 12.sp
                                )
                                val eligibleParties = parties.filter {
                                    it.leaderId == account.userId &&
                                        it.memberIds.size in mission.minMembers..mission.maxMembers
                                }
                                if (eligibleParties.isEmpty()) {
                                    Text(
                                        "لا يوجد فريق تقوده ويطابق شروط هذه المهمة. لا تُضاف شخصيات NPC لتعويض النقص.",
                                        color = Color(0xFFFFC857),
                                        fontSize = 12.sp
                                    )
                                } else {
                                    eligibleParties.forEach { party ->
                                        Button(
                                            enabled = !busy,
                                            onClick = {
                                                busy = true
                                                repository.registerPartyForMission(mission.missionId, party.partyId) { result ->
                                                    result.onSuccess {
                                                        status = "تم تسجيل فريق ${party.name} في مهمة XSX، وحُفظت قائمة أعضائه."
                                                        refresh()
                                                    }.onFailure {
                                                        status = it.message ?: "تعذر تسجيل الفريق في المهمة."
                                                    }
                                                    busy = false
                                                }
                                            },
                                            modifier = Modifier.fillMaxWidth()
                                        ) {
                                            Text("تسجيل فريق ${party.name}")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Text("سجل تسجيلات فرقك", color = Color(0xFFFFC857), fontSize = 20.sp, fontWeight = FontWeight.Bold)
            if (assignments.isEmpty()) {
                Text("لا توجد تسجيلات مهمات مرتبطة بحسابك بعد.", color = Color.LightGray, fontSize = 13.sp)
            } else {
                assignments.forEach { assignment ->
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(containerColor = Color(0xFF18253A)),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Column(
                            Modifier.padding(12.dp),
                            verticalArrangement = Arrangement.spacedBy(5.dp)
                        ) {
                            Text(assignment.missionTitle, color = Color.White, fontWeight = FontWeight.Bold)
                            Text("الفريق: ${assignment.partyName}", color = Color(0xFF55DDF0), fontSize = 12.sp)
                            Text("الحالة: ${assignment.status}", color = Color.LightGray, fontSize = 12.sp)
                            Text(
                                "الأعضاء وقت التسجيل: ${assignment.rosterSnapshot.joinToString { it.second }}",
                                color = Color.LightGray,
                                fontSize = 12.sp
                            )
                        }
                    }
                }
            }
        }
    }
}
