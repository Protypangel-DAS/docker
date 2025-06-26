const axios = require('axios');
const process = require('process');

class AuthGitLab {
  constructor(config, options) {
    this.api = axios.create({
      baseURL: `http://gitlab.local`,
      headers:  { 'Content-Type': 'application/json' },
    });
    this.application_secret = process.env.PLUGIN_AUTH_GITLAB_APPLICATION_SECRET;
    this.application_id = process.env.PLUGIN_AUTH_GITLAB_APPLICATION_ID;
  }

  /** Allow to authenticate with gitlab 
   * @param {string} user - The username to authenticate, could be an email or a username
   * @param {string} password - The password to authenticate
   * @param {function} cb(err, group) - The callback function
   * 
   * @Function cb(err, group) {
   *  @param {Error} err - The error if the authentication failed, if it's not an error you should return null
   *  @param {string[]} group - The group to authenticate, the user must be in this group, if it's not counnected you should return false
   * }
  */
  async authenticate(user, password, cb) {
    try {
      if (!this.application_secret || !this.application_id) {
        console.error('GitLab auth: Missing application credentials');
        throw new Error('GitLab application credentials not configured');
      }

      console.log('GitLab auth: Attempting authentication for user:', user);
      
      const res = await this.api.post('/oauth/token', {
        client_id: this.application_id,
        client_secret: this.application_secret,
        username: user,
        password: password,
        grant_type: "password",
        scope: "api"
      });

      if (!res.data || !res.data.access_token) {
        console.error('GitLab auth: Invalid response from GitLab');
        throw new Error('Invalid authentication response');
      }

      console.log('GitLab auth: Successfully authenticated user:', user);
      // Return both root and authenticated groups
      cb(null, [user]);
    } catch (err) {
      console.error('GitLab auth: Authentication failed:', err.message);
      if (err.response) {
        console.error('GitLab auth: Response status:', err.response.status);
        console.error('GitLab auth: Response data:', err.response.data);
      }
      cb(err, false);
    }
  }
  /** Allow to check if the user has access to the package
   * @param {USER} user - The username to authenticate, could be an email or a username
   * @param {string} pkg - The package to check access
   * @param {function} cb(err, group) - The callback function
   * 
   * @Function cb(err, group) {
   *  @param {Error} err - The error if the authentication failed, if it's not an error you should return null
   *  @param {string[]} group - The group to authenticate, the user must be in this group, if it's not counnected you should return false
   * }
   * 
   * @object USER {
   *  name: string;
   *  groups: string[]; groups of the user
   *  real_groups: string[]; real groups of the user
   *  error: String; error message
   * }
   * @object PKG {
   *  name: string; package name
   *  version: string; package version
   *  access: string[]; role to access the package
   *  publish: string[]; role to publish the package
   *  unpublish: string[]; role to unpublish the package
   *  proxy: string[]; proxy to the package
   * }
  */
  async allow_access(user, pkg, cb) {
    console.log('GitLab auth: Allowing access for user:', user, 'package:', pkg);
    cb(null, true);
  }
}

module.exports = (config, options) => new AuthGitLab(config, options);
