"""Crear tabla compras

Revision ID: 38d0f737e837
Revises: b50a2971ac07
Create Date: 2025-04-22 12:41:15.811757

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '38d0f737e837'
down_revision = 'b50a2971ac07'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.create_table('compras',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('usuario_id', sa.Integer(), nullable=False),
    sa.Column('metodo_pago_id', sa.Integer(), nullable=False),
    sa.ForeignKeyConstraint(['metodo_pago_id'], ['metodos_pago.id'], ),
    sa.ForeignKeyConstraint(['usuario_id'], ['usuarios.id'], ),
    sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('metodos_pago', schema=None) as batch_op:
        batch_op.add_column(sa.Column('activo', sa.Boolean(), nullable=True))

    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    with op.batch_alter_table('metodos_pago', schema=None) as batch_op:
        batch_op.drop_column('activo')

    op.drop_table('compras')
    # ### end Alembic commands ###
