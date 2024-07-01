#!/bin/bash

# Variables de configuración
DB_NAME="nombre_base_de_datos"
DB_USER="usuario_base_de_datos"
DB_PASS="contrasena_base_de_datos"
DB_HOST="localhost"
PS_PATH="/ruta/a/tu/prestashop"
PS_TABLE_PREFIX="ps_" # Ajusta el prefijo de las tablas si es necesario

# Añadir campo email a la tabla supplier
echo "Añadiendo campo email a la tabla supplier..."
mysql -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME -e "ALTER TABLE ${PS_TABLE_PREFIX}supplier ADD email VARCHAR(255) NULL;"

# Crear el archivo de override para Supplier.php
SUPPLIER_OVERRIDE_PATH="${PS_PATH}/override/classes/Supplier.php"
mkdir -p "$(dirname $SUPPLIER_OVERRIDE_PATH)"
cat <<EOL > $SUPPLIER_OVERRIDE_PATH
<?php

class Supplier extends SupplierCore
{
    public \$email;

    public static \$definition = array(
        'table' => 'supplier',
        'primary' => 'id_supplier',
        'fields' => array(
            // Add the email field definition
            'email' => array('type' => self::TYPE_STRING, 'validate' => 'isEmail', 'size' => 255),
            // ... other existing fields ...
        ),
    );

    public function __construct(\$id_supplier = null)
    {
        self::\$definition['fields']['email'] = array('type' => self::TYPE_STRING, 'validate' => 'isEmail', 'size' => 255);
        parent::__construct(\$id_supplier);
    }
}
EOL

# Crear el archivo de override para AdminSuppliersController.php
ADMIN_SUPPLIERS_CONTROLLER_OVERRIDE_PATH="${PS_PATH}/override/controllers/admin/AdminSuppliersController.php"
mkdir -p "$(dirname $ADMIN_SUPPLIERS_CONTROLLER_OVERRIDE_PATH)"
cat <<EOL > $ADMIN_SUPPLIERS_CONTROLLER_OVERRIDE_PATH
<?php

class AdminSuppliersController extends AdminSuppliersControllerCore
{
    public function renderForm()
    {
        \$this->fields_form = array(
            'legend' => array(
                'title' => \$this->l('Suppliers'),
                'icon' => 'icon-truck'
            ),
            'input' => array(
                array(
                    'type' => 'text',
                    'label' => \$this->l('Email'),
                    'name' => 'email',
                    'size' => 255,
                    'required' => false,
                    'hint' => \$this->l('Invalid characters:') . ' <>;=#{}',
                ),
                // ... other existing fields ...
            ),
            'submit' => array(
                'title' => \$this->l('Save'),
            )
        );

        return parent::renderForm();
    }
}
EOL

# Borrar caché de PrestaShop
echo "Borrando caché de PrestaShop..."
rm -rf ${PS_PATH}/var/cache/*

echo "Proceso completado. El campo de email ha sido añadido a los proveedores."
