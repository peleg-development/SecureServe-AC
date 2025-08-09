
new Vue({
    el: '#app',
    data: {
        showMenu: false,
        selectedSection: 'dashboard',
        totalPlayers: 100,
        activeCheaters: 3,
        serverUptime: '72 hours',
        peakPlayers: 150,
        searchQuery: '',
        banSearchQuery: '',
        showModal: false,
        modalBan: {},
        showScreenshotModal: false,
        modalScreenshot: '',
        players: [
            { id: 1, name: 'John Doe', steamId: 'STEAM_0:1:12345678', ping: 50 },
            { id: 2, name: 'Jane Smith', steamId: 'STEAM_0:1:87654321', ping: 75 },
            { id: 3, name: 'Chris Johnson', steamId: 'STEAM_0:1:23456789', ping: 30 },
            { id: 4, name: 'Sarah Lee', steamId: 'STEAM_0:1:98765432', ping: 120 },
            // { id: 5, name: 'Mike Brown', steamId: 'STEAM_0:1:34567890', ping: 90 },
            // { id: 6, name: 'Emma Davis', steamId: 'STEAM_0:1:54321098', ping: 60 },
            // { id: 6, name: 'Emma Davis', steamId: 'STEAM_0:1:54321098', ping: 60 },
            // { id: 6, name: 'Emma Davis', steamId: 'STEAM_0:1:54321098', ping: 60 },
            // { id: 6, name: 'Emma Davis', steamId: 'STEAM_0:1:54321098', ping: 60 },
            // { id: 6, name: 'Emma Davis', steamId: 'STEAM_0:1:54321098', ping: 60 },
        ],
        bans: [
            // { id: 1, name: "Jane Smith", reason: "Abusive language", steam: "STEAM_0:1:87654321", discord: "Jane#1234", hwid1: "HWID123456", ip: "192.168.1.100", expire: "Permanent" },
            // { id: 2, name: "Chris Johnson", reason: "Cheating", steam: "STEAM_0:1:23456789", discord: "Chris#5678", hwid1: "HWID987654", ip: "192.168.1.101", expire: "2025-01-07" },
            // { id: 3, name: "Mike Brown", reason: "Using exploits", steam: "STEAM_0:1:34567890", discord: "Mike#4321", hwid1: "HWID765432", ip: "192.168.1.102", expire: "2025-01-10" },
        ],
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
            // { timestamp: "2025-01-01 14:30:00", message: "Player John Doe kicked for cheating." },
            // { timestamp: "2025-01-01 15:00:00", message: "Server restarted by Admin." },
            // { timestamp: "2025-01-01 15:15:00", message: "Player Jane Smith banned for abusive language." },
            // { timestamp: "2025-01-01 16:00:00", message: "Server cache cleared successfully." },
            // { timestamp: "2025-01-01 16:30:00", message: "Screenshot taken for Player Chris Johnson." },
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
              .catch(() => {})
        },
        fetchPlayers() {
            fetch(`https://${GetParentResourceName()}/getPlayers`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            })
            .then(response => response.json())
            .then(data => {
                if (data && data.players) {
                  this.players = data.players;
                }
            })
            .catch(() => {})
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
            fetch(`https://${GetParentResourceName()}/getBans`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            })
            .then(response => response.json())
            .then(data => {
                if (data && data.bans) {
                  this.bans = data.bans;
                }
            })
            .catch(() => {})
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
            fetch(`https://${GetParentResourceName()}/screenshotPlayer`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ playerId })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    this.showNotification(`Screenshot request sent for player ${playerId}.`, 'success');
                } else {
                    this.showNotification(`Failed to send screenshot request for player ${playerId}.`, 'error');
                }
            })
            .catch(error => {
                console.error('Error taking screenshot:', error);
                this.showNotification('Error sending screenshot request.', 'error');
            });
        },        
        closeScreenshotModal() {
            this.showScreenshotModal = false;
            this.modalScreenshot = null;
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

        getNotificationIcon(type) {
            const icons = {
                success: 'fas fa-check',
                error: 'fas fa-exclamation',
                warning: 'fas fa-bell',
                info: 'fas fa-info'
            };
            return icons[type] || 'fas fa-bell';
        },
        copyToClipboard(text) {
            navigator.clipboard.writeText(text).then(() => {
                this.showNotification('Copied to clipboard', 'success');
            }).catch(() => {
                this.showNotification('Failed to copy to clipboard', 'error');
            });
        },
        showNotification(message, type = 'info') {
            const id = Date.now();
            this.notifications.push({ id, message, type });
            
            setTimeout(() => {
                this.removeNotification(id);
            }, 4000);
        },
    
        removeNotification(id) {
            const index = this.notifications.findIndex(n => n.id === id);
            if (index > -1) {
                this.notifications.splice(index, 1);
            }
        },

        updateStats(stats) {
            this.totalPlayers = stats.totalPlayers;
            this.activeCheaters =  stats.activeCheaters;
            this.serverUptime = stats.serverUptime;
            this.peakPlayers = stats.peakPlayers;
        },
        executeServerOption(action) {
            fetch(`https://${GetParentResourceName()}/executeServerOption`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ action }) 
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    this.showNotification(`Executing server action: ${action}`, 'success');
                } else {
                    this.showNotification('Failed to execute server action.', 'error');
                }
            })
            .catch(error => {
                console.error('Error executing server action:', error);
                this.showNotification('Error executing server action.', 'error');
            });
        },        
        clearAllEntities() {
            this.showNotification('Clearing all entities', 'success');
            fetch(`https://${GetParentResourceName()}/clearAllEntities`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
        },
        getLogIcon(type) {
            switch (type) {
                case 'error':
                    return 'fa-times-circle log-icon error';
                case 'warning':
                    return 'fa-exclamation-circle log-icon warning';
                case 'success':
                    return 'fa-check-circle log-icon success';
                default:
                    return 'fa-info-circle log-icon';
            }
        },
        getOptionIcon(optionName) {
            const icons = {
                'Restart Server': 'fas fa-sync',
                'Shutdown Server': 'fas fa-power-off',
                'Clear Cache': 'fas fa-broom',
                'Update Scripts': 'fas fa-code',
                'Backup Database': 'fas fa-database',
            };
            return icons[optionName] || 'fas fa-cog';
        },
        showScreenshot(data) {
            this.modalScreenshot = data.imageUrl;
            this.showScreenshotModal = true;
        },
        handleKeydown(event) {
            if (event.key === 'Escape') {
                if (this.showScreenshotModal) {
                    this.closeScreenshotModal();
                } else if (this.showMenu) {
                    this.showMenu = false;
                    fetch(`https://${GetParentResourceName()}/close`, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({})
                    });
                }
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
                    this.refresh = event.data.refresh || { players: 5000, bans: 15000, stats: 10000 };
                    if (this._playersTimer) clearInterval(this._playersTimer);
                    if (this._bansTimer) clearInterval(this._bansTimer);
                    if (this._statsTimer) clearInterval(this._statsTimer);
                    this._playersTimer = setInterval(() => this.fetchPlayers(), this.refresh.players);
                    this._bansTimer = setInterval(() => this.fetchBans(), this.refresh.bans);
                    this._statsTimer = setInterval(() => this.fetchDashboardStats(), this.refresh.stats);
                    break;
                case "close":
                    this.showMenu = false;
                    if (this._playersTimer) clearInterval(this._playersTimer);
                    if (this._bansTimer) clearInterval(this._bansTimer);
                    if (this._statsTimer) clearInterval(this._statsTimer);
                    break;
                case "dashboardStats":
                    this.updateStats(event.data);
                    break;
                case "players":
                    console.log(event.data.players)
                    this.players = event.data.players
                    break;
                case "bans":
                    if (event.data && event.data.bans) {
                      this.bans = event.data.bans
                    }
                    break;
                case "displayScreenshot":
                    this.showScreenshot(event.data);
            }
        });
        window.addEventListener('keydown', this.handleKeydown);
    },
    beforeDestroy() {
        window.removeEventListener('keydown', this.handleKeydown);
    }
});
