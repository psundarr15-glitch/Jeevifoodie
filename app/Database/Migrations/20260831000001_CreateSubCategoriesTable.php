<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class CreateSubCategoriesTable extends Migration
{
    public function up()
    {
        $this->forge->addField([
            'id'            => ['type' => 'INT', 'unsigned' => true, 'auto_increment' => true],
            // The main/top-level category (e.g. "Indian Food") this
            // sub-category (e.g. "Biryani") belongs under - created by
            // the app owner in the existing `categories` table.
            'category_id'   => ['type' => 'INT', 'unsigned' => true],
            // Each restaurant manages its own set of sub-categories -
            // one manager's "Biryani" is a different row from another
            // restaurant's "Biryani", even under the same main category.
            'restaurant_id' => ['type' => 'INT', 'unsigned' => true],
            'name'          => ['type' => 'VARCHAR', 'constraint' => 100],
            'name_ta'       => ['type' => 'VARCHAR', 'constraint' => 100, 'null' => true],
        ]);
        $this->forge->addKey('id', true);
        $this->forge->addKey('restaurant_id');
        $this->forge->addKey('category_id');
        $this->forge->createTable('sub_categories');

        // Menu items now group under a sub-category ("Biryani") rather
        // than directly under a main category ("Indian Food") - the
        // existing category_id column stays as-is (unused going
        // forward) so no menu item data is lost; items just need
        // re-categorizing into the new sub-categories.
        $this->forge->addColumn('menu_items', [
            'sub_category_id' => ['type' => 'INT', 'unsigned' => true, 'null' => true, 'after' => 'category_id'],
        ]);
    }

    public function down()
    {
        $this->forge->dropColumn('menu_items', ['sub_category_id']);
        $this->forge->dropTable('sub_categories');
    }
}
