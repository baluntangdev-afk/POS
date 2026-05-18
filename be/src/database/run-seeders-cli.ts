import { runSeeders } from './run-seeders';

runSeeders()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
