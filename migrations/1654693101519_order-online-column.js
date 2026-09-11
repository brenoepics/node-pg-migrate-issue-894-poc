/* eslint-disable camelcase */

// The new migration from the issue, unchanged.

exports.shorthands = undefined;

const table = 'business_profile';

exports.up = (pgm) => {
  pgm.addColumn(table, {
    order_online_call_to_action_type: { type: 'varchar(255)' },
  });
  pgm.alterColumn(table, 'business_description', { type: 'text' });
};

exports.down = (pgm) => {
  pgm.dropColumn(table, 'order_online_call_to_action_type', { ifExists: true });
  pgm.alterColumn(table, 'business_description', { type: 'varchar(255)' });
};
