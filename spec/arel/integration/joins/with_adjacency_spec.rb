require File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper')

module Arel
  describe Join do
    before do
      @relation1 = Table.new(:users)
      @relation2 = @relation1.alias
      @predicate = @relation1[:id].eq(@relation2[:id])
    end
    
    describe 'when joining a relation to itself' do
      describe '#to_sql' do
        it 'manufactures sql aliasing the table and attributes properly in the join predicate and the where clause' do
          @relation1.join(@relation2).on(@predicate).to_sql.should be_like("
            SELECT `users`.`id`, `users`.`name`, `users_2`.`id`, `users_2`.`name`
            FROM `users`
              INNER JOIN `users` AS `users_2`
                ON `users`.`id` = `users_2`.`id`
          ")
        end
        
        describe 'when joining with a selection on the same relation' do
          it 'manufactures sql aliasing the tables properly' do
            @relation1                                                      \
              .join(@relation2.select(@relation2[:id].eq(1)))               \
                .on(@predicate)                                             \
            .to_sql.should be_like("
              SELECT `users`.`id`, `users`.`name`, `users_2`.`id`, `users_2`.`name`
              FROM `users`
                INNER JOIN `users` AS `users_2`
                  ON `users`.`id` = `users_2`.`id` AND `users_2`.`id` = 1
            ")
          end
          
          describe 'when the selection occurs before the alias' do
            it 'manufactures sql aliasing the predicates properly' do
              relation2 = @relation1.select(@relation1[:id].eq(1)).alias
              @relation1                                  \
                .join(relation2)                          \
                  .on(relation2[:id].eq(@relation1[:id])) \
              .to_sql.should be_like("
                SELECT `users`.`id`, `users`.`name`, `users_2`.`id`, `users_2`.`name`
                FROM `users`
                INNER JOIN `users` AS `users_2`
                  ON `users_2`.`id` = `users`.`id` AND `users_2`.`id` = 1
              ")
            end
          end
        end
        
        describe 'when joining the relation to itself multiple times' do
          before do
            @relation3 = @relation1.alias
          end
          
          describe 'when joining left-associatively' do
            it 'manufactures sql aliasing the tables properly' do
              @relation1                                      \
                .join(@relation2                              \
                  .join(@relation3)                           \
                    .on(@relation2[:id].eq(@relation3[:id]))) \
                  .on(@relation1[:id].eq(@relation2[:id]))                                 \
              .to_sql.should be_like("
                SELECT `users`.`id`, `users`.`name`, `users_2`.`id`, `users_2`.`name`, `users_3`.`id`, `users_3`.`name`
                FROM `users`
                  INNER JOIN `users` AS `users_2`
                    ON `users`.`id` = `users_2`.`id`
                  INNER JOIN `users` AS `users_3`
                    ON `users_2`.`id` = `users_3`.`id`
              ")
            end
          end
          
          describe 'when joining right-associatively' do
            it 'manufactures sql aliasing the tables properly' do
              @relation1                                                    \
                .join(@relation2).on(@relation1[:id].eq(@relation2[:id]))   \
                .join(@relation3).on(@relation2[:id].eq(@relation3[:id]))   \
              .to_sql.should be_like("
                SELECT `users`.`id`, `users`.`name`, `users_2`.`id`, `users_2`.`name`, `users_3`.`id`, `users_3`.`name`
                FROM `users`
                  INNER JOIN `users` AS `users_2`
                    ON `users`.`id` = `users_2`.`id`
                  INNER JOIN `users` AS `users_3`
                    ON `users_2`.`id` = `users_3`.`id`
              ")
            end
          end
        end
      end
        
      describe '[]' do
        describe 'when given an attribute belonging to both sub-relations' do
          it 'disambiguates the relation that serves as the ancestor to the attribute' do
            @relation1          \
              .join(@relation2) \
                .on(@predicate) \
            .should disambiguate_attributes(@relation1[:id], @relation2[:id])
          end
          
          describe 'when the left relation is extremely compound' do
            it 'disambiguates the relation that serves as the ancestor to the attribute' do
              @relation1            \
                .select(@predicate) \
                .select(@predicate) \
                .join(@relation2)   \
                  .on(@predicate)   \
              .should disambiguate_attributes(@relation1[:id], @relation2[:id])
            end
          end
          
          describe 'when the right relation is extremely compound' do
            it 'disambiguates the relation that serves as the ancestor to the attribute' do
              @relation1                  \
                .join(                    \
                  @relation2              \
                    .select(@predicate)   \
                    .select(@predicate)   \
                    .select(@predicate))  \
                  .on(@predicate)         \
              .should disambiguate_attributes(@relation1[:id], @relation2[:id])
            end
          end
        end
      end
    end
  end
end