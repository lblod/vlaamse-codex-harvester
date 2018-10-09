import { harvest } from './lod-harvester';

const types = [
  'eli:LegalResource',
  'eli:LegalResourceSubdivision',
  'eli:LegalExpression'
];
const sparqlEndpoint = 'http://staging.opendata.codex.vandenbroele.be:8888/sparql';
process.env.MU_SPARQL_ENDPOINT = sparqlEndpoint;
const file = '/app/output/output.ttl';

harvest(sparqlEndpoint, types, file);
