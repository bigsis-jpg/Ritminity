/**
 * RITMINITY - API Client
 * JavaScript client for communicating with the backend API
 */

const API = {
    baseUrl: 'api/',
    token: null,
    
    /**
     * Set authentication token
     */
    setToken(token) {
        this.token = token;
        localStorage.setItem('ritminity_token', token);
    },
    
    /**
     * Get authentication token
     */
    getToken() {
        if (!this.token) {
            this.token = localStorage.getItem('ritminity_token');
        }
        return this.token;
    },
    
    /**
     * Clear authentication token
     */
    clearToken() {
        this.token = null;
        localStorage.removeItem('ritminity_token');
    },
    
    /**
     * Make API request
     */
    async request(endpoint, options = {}) {
        const url = this.baseUrl + endpoint;
        
        const headers = {
            'Content-Type': 'application/json',
            ...options.headers
        };
        
        const token = this.getToken();
        if (token) {
            headers['Authorization'] = token;
        }
        
        const config = {
            ...options,
            headers
        };
        
        try {
            const response = await fetch(url, config);
            const data = await response.json();
            
            if (!response.ok) {
                throw new Error(data.error || 'Request failed');
            }
            
            return data;
        } catch (error) {
            console.error('API Error:', error);
            throw error;
        }
    },
    
    /**
     * GET request
     */
    async get(endpoint, params = {}) {
        const query = new URLSearchParams(params).toString();
        const url = query ? `${endpoint}?${query}` : endpoint;
        return this.request(url, { method: 'GET' });
    },
    
    /**
     * POST request
     */
    async post(endpoint, data = {}) {
        return this.request(endpoint, {
            method: 'POST',
            body: JSON.stringify(data)
        });
    },
    
    /**
     * PUT request
     */
    async put(endpoint, data = {}) {
        return this.request(endpoint, {
            method: 'PUT',
            body: JSON.stringify(data)
        });
    },
    
    /**
     * DELETE request
     */
    async delete(endpoint) {
        return this.request(endpoint, { method: 'DELETE' });
    },
    
    // ==================== AUTH ====================
    
    /**
     * Login user
     */
    async login(username, password) {
        const data = await this.post('auth/login', { username, password });
        if (data.success && data.token) {
            this.setToken(data.token);
        }
        return data;
    },
    
    /**
     * Register user
     */
    async register(username, email, password, country = 'US') {
        return this.post('auth/register', { username, email, password, country });
    },
    
    /**
     * Logout user
     */
    async logout() {
        const token = this.getToken();
        if (token) {
            await this.post('auth/logout', { token });
        }
        this.clearToken();
    },
    
    // ==================== MAPS ====================
    
    /**
     * Get maps
     */
    async getMaps(params = {}) {
        return this.get('maps', params);
    },
    
    /**
     * Get single map
     */
    async getMap(id) {
        return this.get(`maps/${id}`);
    },
    
    /**
     * Upload map
     */
    async uploadMap(mapData) {
        return this.post('maps', mapData);
    },
    
    // ==================== SCORES ====================
    
    /**
     * Get scores
     */
    async getScores(params = {}) {
        return this.get('scores', params);
    },
    
    /**
     * Submit score
     */
    async submitScore(scoreData) {
        return this.post('scores', scoreData);
    },
    
    // ==================== LEADERBOARD ====================
    
    /**
     * Get leaderboard
     */
    async getLeaderboard(type = 'score', page = 1, limit = 20) {
        return this.get('leaderboard', { type, page, limit });
    },
    
    // ==================== USERS ====================
    
    /**
     * Get user profile
     */
    async getUser(id) {
        return this.get(`users/${id}`);
    },
    
    /**
     * Get current user profile
     */
    async getMe() {
        return this.get('users/me');
    },
    
    /**
     * Update user profile
     */
    async updateUser(id, data) {
        return this.put(`users/${id}`, data);
    },
    
    // ==================== STATS ====================
    
    /**
     * Get global stats
     */
    async getGlobalStats() {
        return this.get('stats', { type: 'global' });
    },
    
    /**
     * Get user stats
     */
    async getUserStats(userId) {
        return this.get('stats', { type: 'user', user_id: userId });
    },
    
    /**
     * Get map stats
     */
    async getMapStats(mapId) {
        return this.get('stats', { type: 'map', map_id: mapId });
    },
    
    // ==================== REPLAYS ====================
    
    /**
     * Get replay
     */
    async getReplay(id) {
        return this.get(`replays/${id}`);
    },
    
    /**
     * Save replay
     */
    async saveReplay(replayData) {
        return this.post('replays', replayData);
    }
};

// Export for use in other files
window.API = API;