/* eslint-disable camelcase */

// The "old" migration from the issue. It already ran - see reproduce.sh, step 1.

exports.shorthands = undefined;

exports.up = (pgm) => {
  pgm.addColumn('users', { contract_id: { type: 'varchar(255)' } });
};

exports.down = (pgm) => {
  pgm.dropColumn('users', 'contract_id');
};
