val updatedDomains = current.domains.map { item ->
    if (item.domain == domain) {
        item.copy(
            completedTasks = item.completedTasks + 1,
            totalTasks = item.totalTasks + 1
        )
    } else {
        item
    }
}
