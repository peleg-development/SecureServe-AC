
new Vue({
    el: '#app',
    data: {
        showMenu: true,
        selectedSection: 'dashboard',
        totalPlayers: 100,
        activeCheaters: 3,
        serverUptime: '72 hours',
        peakPlayers: 150,
        searchQuery: '',
        banSearchQuery: '',
        showModal: false,
        modalBan: {},
        players: [
        ],
        bans: [],
        selectedPlayer: null,
        playerOptions: [
            { name: 'ESP', enabled: false, type: 'toggle', category: 'misc' },
            { name: 'Player Names', enabled: false, type: 'toggle', category: 'misc' },
            { name: 'God Mode', enabled: false, type: 'toggle', category: 'admin' },
            { name: 'No Clip', enabled: false, type: 'toggle', category: 'admin' },
            { name: 'Invisibility', enabled: false, type: 'toggle', category: 'misc' },
            { name: 'Bones', enabled: false, type: 'toggle', category: 'misc' },
            { name: 'Repair Vehicle', enabled: false, type: 'button', category: 'admin' },
            { name: 'Teleport', enabled: false, type: 'button', category: 'admin' }
        ],
        lastUpdates: [
            { id: 1, title: "Update 1", description: "Resolved server lag issues to enhance performance.", date: "2025-01-01" },
            { id: 2, title: "Update 2", description: "Implemented fixes to improve the admin panel's functionality.", date: "2025-01-03" },
            { id: 3, title: "Update 3", description: "Redesigned the admin panel interface and resolved existing issues for a better user experience.", date: "2025-01-04" },
        ],
        serverOptions: [
            { name: 'Restart Server', action: 'restart' },
            { name: 'Shutdown Server', action: 'shutdown' },
            { name: 'Clear Cache', action: 'clear_cache' },
            { name: 'Update Scripts', action: 'update_scripts' },
            { name: 'Backup Database', action: 'backup_database' },
        ],
        logs: [

        ],
        settings: {
            notifications: true,
            darkMode: false
        },
        vehicleName: '',
        showObjectSpawner: false,
        spawnObject: '',
        objectName: '',
        pedModel: '',
        notifications: [],
        notificationId: 0
    },
    methods: {
        fetchDashboardStats() {
            fetch(`https://${GetParentResourceName()}/getDashboardStats`, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({})  
            })
              .then(response => response.json())
              .then(data => {
                this.totalPlayers   = data.totalPlayers;
                this.activeCheaters = data.activeCheaters;
                this.serverUptime   = data.serverUptime;
                this.peakPlayers    = data.peakPlayers;
              })
              .catch(error => {
                console.error('Error fetching dashboard stats:', error);
              });

        },
        fetchPlayers() {
            fetch(`https://${GetParentResourceName()}/getPlayers`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            })
            .then(response => response.json())
            .then(data => {
                this.players = data.players;
            })
            .catch(error => {
                console.error('Error fetching players:', error);
            });
        },
        kickPlayer(playerId) {
            fetch(`https://${GetParentResourceName()}/kickPlayer`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ playerId: playerId })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    this.showNotification(`Player ${playerId} kicked successfully`, 'success');
                    this.fetchPlayers();
                } else {
                    this.showNotification(`Failed to kick player ${playerId}`, 'error');
                }
            })
            .catch(error => {
                console.error('Error kicking player:', error);
                this.showNotification(`Error kicking player ${playerId}`, 'error');
            });
        },
        banPlayer(playerId) {
            fetch(`https://${GetParentResourceName()}/banPlayer`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ playerId: playerId })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    this.showNotification(`Player ${playerId} banned successfully`, 'success');
                    this.fetchPlayers();
                } else {
                    this.showNotification(`Failed to ban player ${playerId}`, 'error');
                }
            })
            .catch(error => {
                console.error('Error banning player:', error);
                this.showNotification(`Error banning player ${playerId}`, 'error');
            });
        },
        spectatePlayer(playerId) {
            fetch(`https://${GetParentResourceName()}/spectatePlayer`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ playerId: playerId })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    this.showNotification(`Spectating player ${playerId}`, 'success');
                } else {
                    this.showNotification(`Failed to spectate player ${playerId}`, 'error');
                }
            })
            .catch(error => {
                console.error('Error spectating player:', error);
                this.showNotification(`Error spectating player ${playerId}`, 'error');
            });
        },
        fetchBans() {
            fetch('/bans.json')
                .then(response => response.json())
                .then(data => {
                    this.bans = data;
                })
                .catch(error => {
                    console.error('Error fetching bans:', error);
                });
        },
        unbanPlayer(banId) {
            fetch(`https://${GetParentResourceName()}/unbanPlayer`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ banId: banId })
            }).then(response => {
                if (response.ok) {
                    this.bans = this.bans.filter(ban => ban.id !== banId);
                    this.showNotification(`Player with ID ${banId} unbanned successfully`, 'success');
                } else {
                    this.showNotification(`Failed to unban player with ID ${banId}`, 'error');
                }
            }).catch(error => {
                console.error('Error unbanning player:', error);
                this.showNotification(`Error unbanning player with ID ${banId}`, 'error');
            });
        },
        selectSection(section) {
            this.selectedSection = section;
        },
        screenshotPlayer(playerId) {
            this.showNotification(`Taking a screenshot of player ${playerId}`, 'success');
        },
        showBanInfo(ban) {
            this.modalBan = ban;
            this.showModal = true;
        },
        closeModal() {
            this.showModal = false;
            this.modalBan = {};
        },
        objectSpawn() {
            this.showNotification(`Spawning object: ${this.objectName}`, 'success');
            this.objectName = '';
        },
        changePed() {
            this.showNotification(`Changing ped model to: ${this.pedModel}`, 'success');
            this.pedModel = '';
        },
        spawnVehicle() {
            this.showNotification(`Spawning vehicle: ${this.vehicleName}`, 'success');
            this.vehicleName = '';
        },
        openObjectSpawner() {
            this.showObjectSpawner = true;
        },
        closeObjectSpawner() {
            this.showObjectSpawner = false;
            this.spawnObject = '';
        },
        spawnObjectAction() {
            this.showNotification(`Spawning object: ${this.spawnObject}`, 'success');
            this.closeObjectSpawner();
        },
        deleteAllVehicles() {
            this.showNotification('Deleting all vehicles', 'success');
        },
        toggleOptiona(option) {
            const enabled = this.playerOptions.find(o => o.name === option).enabled;
            fetch(`https://${GetParentResourceName()}/toggleOptiona`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ option, enabled })
            });
        },
        showNotification(message, type) {
            const id = this.notificationId++;
            this.notifications.push({ id, message, type });
            setTimeout(() => {
                this.removeNotification(id);
            }, 3000);
        },
        updateStats(stats) {
            this.totalPlayers = stats.totalPlayers;
            this.activeCheaters =  stats.activeCheaters;
            this.serverUptime = stats.serverUptime;
            this.peakPlayers = stats.peakPlayers;
        },
        removeNotification(id) {
            this.notifications = this.notifications.filter(notification => notification.id !== id);
        },
        executeServerOption(action) {
            this.showNotification(`Executing server action: ${action}`, 'success');
        },
        clearAllEntities() {
            this.showNotification('Clearing all entities', 'success');
            fetch(`https://${GetParentResourceName()}/clearAllEntities`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
        },
        handleKeydown(event) {
            if (event.key === 'Escape') {
                this.showMenu = false;
                fetch(`https://${GetParentResourceName()}/close`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ })
                });
            }
        },
    },
    computed: {
        filteredPlayers() {
            return this.players.filter(player => {
                return player.name.toLowerCase().includes(this.searchQuery.toLowerCase());
            });
        },
        filteredBans() {
            return this.bans.filter(ban => {
                return ban.name.toLowerCase().includes(this.banSearchQuery.toLowerCase());
            });
        }
    },
    mounted() {

        window.addEventListener('message', (event) => {
            let action = event.data.action;
            switch (action) {
                case "open":
                    this.fetchBans(); 
                    this.fetchPlayers(); 
                    this.fetchDashboardStats();
                    this.showMenu = true;
                    break;
                case "close":
                    this.showMenu = false;
                    break;
                case "dashboardStats":
                    this.updateStats(event.data);
                    break;
                case "players":
                    console.log(event.data.players)
                    this.players = event.data.players
                    break
            }
        });
        window.addEventListener('keydown', this.handleKeydown);
    },
    beforeDestroy() {
        window.removeEventListener('keydown', this.handleKeydown);
    }
});
