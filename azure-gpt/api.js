
import { config } from './config.js';

function headers() {
  return {
    'Authorization': 'Basic ' + btoa(':' + config.pat),
    'Content-Type': 'application/json'
  };
}

export async function wiql(query) {
  const url = `${config.baseUrl}/${config.organization}/${config.project}/_apis/wit/wiql?api-version=7.0`;
  const r = await fetch(url, { method:'POST', headers: headers(), body: JSON.stringify({query})});
  return r.json();
}

export async function workItem(id) {
  const url = `${config.baseUrl}/${config.organization}/_apis/wit/workitems/${id}?$expand=all&api-version=7.0`;
  return fetch(url,{headers:headers()}).then(r=>r.json());
}

export async function sprintWork(team, sprint) {
  const url = `${config.baseUrl}/${config.organization}/${config.project}/${team}/_apis/work/teamsettings/iterations?api-version=7.0`;
  return fetch(url,{headers:headers()}).then(r=>r.json());
}
