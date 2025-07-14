import axios from 'axios';

const args = process.argv.slice(2);

const baseURL = axios.create({
  baseURL: 'http://gitlab.local',
  headers: { 'PRIVATE-TOKEN': args[0], 'Content-Type': 'application/json' },
})

const api = axios.create({
  baseURL: `http://gitlab.local/api/v4`,
  headers:  { 'PRIVATE-TOKEN': args[0], 'Content-Type': 'application/json' },
});

async function createGroup(name) {
  const { data } = await api.post('/groups', {
    name,
    path: name,
    visibility: 'internal',
  });
  return data.id;
}

async function createProject(namespaceId, name) {
  const { data } = await api.post('/projects', {
    name,
    path: name,
    namespace_id: namespaceId,
    visibility: 'internal',
  });
  return data.id;
}

async function createApplicationIdAndSecretForVerdaccio() {
  const { data } = await api.post('/applications', {
    name: 'Verdaccio-auth-gitlab',
    redirect_uri: 'http://localhost:4873/oauth/callback',
    scopes: 'api'
  });
  return {
    application_id: data.application_id,
    application_secret: data.secret,
  };
}

const name = "storybook";
const idGroup = await createGroup(name);
const idProject = await createProject(idGroup, name);
const applicationIdAndSecret = await createApplicationIdAndSecretForVerdaccio();

console.log(applicationIdAndSecret.application_id);
console.log(applicationIdAndSecret.application_secret);

