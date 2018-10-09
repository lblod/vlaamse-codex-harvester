import fs from 'fs-extra';
import request from 'request';
// import SC2 from 'sparql-client-2';
// const { SparqlClient } = SC2;
import { query } from 'mu';

const batchSize = 1000;
const prefixes = prefixStatements({
  'eli': 'http://data.europa.eu/eli/ontology#'
});

async function harvest(sparqlEndpoint, types, file) {

  const tmpFile = `${file}.tmp`;

  for (var type of types) {
    const count = await countForType(sparqlEndpoint, prefixes, type);
    console.log(`Exporting 0/${count} of ${type}`);

    let offset = 0;
    const query = `${prefixes}
      CONSTRUCT {
        ${constructStatementsForType(type)}
      }
      WHERE {
        {
          SELECT DISTINCT ?resource WHERE {
            ${whereStatementsForType(type)}
          }
          LIMIT ${batchSize} OFFSET %OFFSET
        }
        ${whereStatementsForType(type)}
      }
    `;

    while (offset < count) {
      await appendBatch(tmpFile, sparqlEndpoint, query, offset);
      offset = offset + batchSize;
      console.log(`Constructed ${offset < count ? offset : count}/${count} of ${type}`);
    }
  };
  await fs.rename(tmpFile, file);
}

// private

async function appendBatch(file, sparqlEndpoint, query, offset = 0, limit = 1000) {
  const format = 'text/turtle';
  const options = {
    method: 'POST',
    url: sparqlEndpoint,
    headers: {
      'Accept': format
    },
    qs: {
      format: format,
      query: query.replace('%OFFSET', offset)
    }
  };

  return new Promise ( (resolve,reject) => {
    console.log(options.qs.query);
    const writer = fs.createWriteStream(file, { flags: 'a' });
    try {
      writer.on('finish', resolve);
      return request(options)
        .on('error', (error) => { reject(error); })
        .on('end', () => { writer.end("\n"); })
        .pipe(writer, { end: false });
    }
    catch(e) {
      writer.end();
      return reject(e);
    }
  });
}


function prefixStatements(prefixes) {
  return Object.keys(prefixes).map(function(prefix, index) {
    return `PREFIX ${prefix}: <${prefixes[prefix]}>`;
  }).join('\n');
}

async function countForType(sparqlEndpoint, prefixes, type) {
  const queryResult = await query(`${prefixes}
      SELECT (COUNT(DISTINCT(?resource)) as ?count)
      WHERE {
        ${whereStatementsForType(type)}
      }
    `);

  return parseInt(queryResult.results.bindings[0].count.value);
}

function constructStatementsForType(type) {
  const construct = [];
  construct.push(`?resource a ${type}.`);
  construct.push(`?resource ?p ?o.`);  
  return construct.join('\n');
}

function whereStatementsForType(type) {
  const where = [];
  where.push(`?resource a ${type}.`);
  where.push(`?resource ?p ?o.`);
  return where.join('\n');
}

export default harvest;
export { harvest };
