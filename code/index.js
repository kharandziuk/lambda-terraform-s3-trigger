
exports.handler = (event, context, callback) => {
  const key = event.Records[0].s3.object.key;
  console.log(`${key} was removed`)
  callback(null, `${key} was removed`)
}
