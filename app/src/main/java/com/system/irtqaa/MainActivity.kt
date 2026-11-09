if (selectedTab != 0 || showWorldSelection) {

    // اللوحة الجانبية الثابتة
    Column(
        modifier = Modifier
            .width(260.dp)
            .fillMaxHeight()
            .verticalScroll(rememberScrollState())
            .padding(end = 12.dp)
    ) {
        // يبقى محتوى اللوحة الجانبية الحالي كما هو
    }
}
