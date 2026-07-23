require 'spec_helper'

describe FilterSummary do
  describe '#to_s' do
    it 'returns nil when no filter params are present' do
      expect(described_class.new({}).to_s).to be_nil
    end

    describe 'machine identity' do
      it 'returns nil when more than one machine param family is present' do
        machine = FactoryBot.create(:machine, machine_group: nil)

        summary = described_class.new(by_machine_single_id: [ machine.id ], by_opdb_id: [ 'abc' ])

        expect(summary.to_s).to be_nil
      end

      it 'returns nil when the ids do not resolve to any machine' do
        summary = described_class.new(by_machine_single_id: [ 0 ])

        expect(summary.to_s).to be_nil
      end

      describe 'by_machine_single_id' do
        it 'shows the specific machine name, not the group name, even when grouped' do
          group = FactoryBot.create(:machine_group, name: 'Godzilla')
          machine = FactoryBot.create(:machine, name: 'Godzilla (Pro)', machine_group: group)

          summary = described_class.new(by_machine_single_id: [ machine.id ])

          expect(summary.to_s).to eq('Godzilla (Pro)')
        end
      end

      describe 'by_opdb_id' do
        it 'shows the specific machine name, not the group name' do
          group = FactoryBot.create(:machine_group, name: 'Godzilla')
          machine = FactoryBot.create(:machine, name: 'Godzilla (Pro)', machine_group: group, opdb_id: 'GweeP-MW95j')

          summary = described_class.new(by_opdb_id: [ 'GweeP-MW95j' ])

          expect(summary.to_s).to eq('Godzilla (Pro)')
        end
      end

      describe 'by_ipdb_id' do
        it 'shows the specific machine name' do
          machine = FactoryBot.create(:machine, name: 'Twilight Zone', machine_group: nil, ipdb_id: 1234)

          summary = described_class.new(by_ipdb_id: [ 1234 ])

          expect(summary.to_s).to eq('Twilight Zone')
        end
      end

      describe 'by_machine_group_id' do
        it 'shows the group name directly' do
          group = FactoryBot.create(:machine_group, name: 'Godzilla')

          summary = described_class.new(by_machine_group_id: [ group.id ])

          expect(summary.to_s).to eq('Godzilla')
        end
      end

      describe 'by_machine_id' do
        it 'shows the group name when the machine belongs to a group' do
          group = FactoryBot.create(:machine_group, name: 'Godzilla')
          machine = FactoryBot.create(:machine, name: 'Godzilla (Pro)', machine_group: group)

          summary = described_class.new(by_machine_id: [ machine.id ])

          expect(summary.to_s).to eq('Godzilla')
        end

        it 'shows the machine name when it is not grouped' do
          machine = FactoryBot.create(:machine, name: 'Twilight Zone', machine_group: nil)

          summary = described_class.new(by_machine_id: [ machine.id ])

          expect(summary.to_s).to eq('Twilight Zone')
        end

        it 'dedupes multiple ids from the same group into one unit' do
          group = FactoryBot.create(:machine_group, name: 'Godzilla')
          pro = FactoryBot.create(:machine, name: 'Godzilla (Pro)', machine_group: group)
          premium = FactoryBot.create(:machine, name: 'Godzilla (Premium)', machine_group: group)

          summary = described_class.new(by_machine_id: [ pro.id, premium.id ])

          expect(summary.to_s).to eq('Godzilla')
        end
      end

      describe 'by_machine_id_ic' do
        it 'appends the Insider Connected clause' do
          group = FactoryBot.create(:machine_group, name: 'Godzilla')
          machine = FactoryBot.create(:machine, name: 'Godzilla (Pro)', machine_group: group)

          summary = described_class.new(by_machine_id_ic: [ machine.id ])

          expect(summary.to_s).to eq('Godzilla with Insider Connected active')
        end
      end

      describe 'by_machine_single_id_ic' do
        it 'appends the Insider Connected clause and does not expand the group' do
          group = FactoryBot.create(:machine_group, name: 'Godzilla')
          machine = FactoryBot.create(:machine, name: 'Godzilla (Pro)', machine_group: group)

          summary = described_class.new(by_machine_single_id_ic: [ machine.id ])

          expect(summary.to_s).to eq('Godzilla (Pro) with Insider Connected active')
        end
      end

      describe 'joining multiple names' do
        it 'joins two names with "or"' do
          m1 = FactoryBot.create(:machine, name: 'Godzilla (Pro)', machine_group: nil)
          m2 = FactoryBot.create(:machine, name: 'Twilight Zone', machine_group: nil)

          summary = described_class.new(by_machine_single_id: [ m1.id, m2.id ])

          expect(summary.to_s).to eq('Godzilla (Pro) or Twilight Zone')
        end

        it 'joins three or more names with commas and a final "or"' do
          m1 = FactoryBot.create(:machine, name: 'Godzilla (Pro)', machine_group: nil)
          m2 = FactoryBot.create(:machine, name: 'Twilight Zone', machine_group: nil)
          m3 = FactoryBot.create(:machine, name: 'Iron Man', machine_group: nil)

          summary = described_class.new(by_machine_single_id: [ m1.id, m2.id, m3.id ])

          expect(summary.to_s).to include('Godzilla (Pro)', 'Twilight Zone', 'Iron Man', ', or ')
        end

        it 'collapses to "multiple machines" once more than 5 units are selected' do
          machines = (1..6).map { |n| FactoryBot.create(:machine, name: "Machine #{n}", machine_group: nil) }

          summary = described_class.new(by_machine_single_id: machines.map(&:id))

          expect(summary.to_s).to eq('multiple machines')
        end

        it 'lists exactly 5 units instead of collapsing' do
          machines = (1..5).map { |n| FactoryBot.create(:machine, name: "Machine #{n}", machine_group: nil) }

          summary = described_class.new(by_machine_single_id: machines.map(&:id))

          expect(summary.to_s).not_to eq('multiple machines')
        end
      end
    end

    describe 'by_type_id' do
      it 'shows the location type name(s)' do
        bar = FactoryBot.create(:location_type, name: 'Bar')

        summary = described_class.new(by_type_id: [ bar.id ])

        expect(summary.to_s).to eq('location type Bar')
      end

      it 'joins multiple type names with "or"' do
        bar = FactoryBot.create(:location_type, name: 'Bar')
        arcade = FactoryBot.create(:location_type, name: 'Arcade')

        summary = described_class.new(by_type_id: [ bar.id, arcade.id ])

        expect(summary.to_s).to include('location type', 'Bar', 'Arcade', ' or ')
      end
    end

    describe 'manufacturer' do
      it 'shows the manufacturer name(s)' do
        summary = described_class.new(manufacturer: [ 'Stern' ])

        expect(summary.to_s).to eq('machines manufactured by Stern')
      end

      it 'joins multiple manufacturers with "or"' do
        summary = described_class.new(manufacturer: [ 'Stern', 'Williams' ])

        expect(summary.to_s).to eq('machines manufactured by Stern or Williams')
      end
    end

    describe 'by_machine_type' do
      it 'labels em/me as EM' do
        summary = described_class.new(by_machine_type: [ 'em', 'me' ])

        expect(summary.to_s).to eq('EM machines')
      end

      it 'labels ss as SS' do
        summary = described_class.new(by_machine_type: [ 'ss' ])

        expect(summary.to_s).to eq('SS machines')
      end
    end

    describe 'machine year range' do
      it 'shows a between phrase when both bounds are present' do
        summary = described_class.new(by_machine_year_gte: '1970', by_machine_year_lte: '1985')

        expect(summary.to_s).to eq('a machine made between 1970 and 1985')
      end

      it 'shows an "or later" phrase for gte only' do
        summary = described_class.new(by_machine_year_gte: '1985')

        expect(summary.to_s).to eq('a machine made in 1985 or later')
      end

      it 'shows an "or earlier" phrase for lte only' do
        summary = described_class.new(by_machine_year_lte: '1970')

        expect(summary.to_s).to eq('a machine made in 1970 or earlier')
      end
    end

    describe 'by_at_least_n_machines and its variants' do
      it 'shows the machine count threshold' do
        summary = described_class.new(by_at_least_n_machines: '5')

        expect(summary.to_s).to eq('at least 5 machines')
      end

      it 'is treated as one category regardless of which variant is set' do
        summary = described_class.new(by_at_least_n_machines_zone: '3')

        expect(summary.to_s).to eq('at least 3 machines')
      end
    end

    describe 'by_is_stern_army' do
      it 'shows a Stern Army clause' do
        summary = described_class.new(by_is_stern_army: '1')

        expect(summary.to_s).to eq('Stern Army')
      end
    end

    describe 'by_ic_active' do
      it 'shows an Insider Connected clause' do
        summary = described_class.new(by_ic_active: '1')

        expect(summary.to_s).to eq('at least one Stern Insider Connected machine')
      end

      it 'is not duplicated when a machine IC family is already active' do
        machine = FactoryBot.create(:machine, machine_group: nil)

        summary = described_class.new(by_ic_active: '1', by_machine_single_id_ic: [ machine.id ])

        expect(summary.to_s).to eq("#{machine.name} with Insider Connected active")
      end
    end

    describe 'by_operator_id' do
      it 'shows the operator name(s)' do
        operator = FactoryBot.create(:operator, name: 'Quarterworld')

        summary = described_class.new(by_operator_id: [ operator.id ])

        expect(summary.to_s).to eq('operator Quarterworld')
      end

      it 'joins multiple operators with "or" (possible via URL even without a multi-select UI)' do
        q = FactoryBot.create(:operator, name: 'Quarterworld')
        gb = FactoryBot.create(:operator, name: 'Ground Kontrol')

        summary = described_class.new(by_operator_id: [ q.id, gb.id ])

        expect(summary.to_s).to include('operator', 'Quarterworld', 'Ground Kontrol', ' or ')
      end
    end

    describe 'by_zone_id' do
      it 'shows the zone name(s)' do
        zone = FactoryBot.create(:zone, name: 'Downtown')

        summary = described_class.new(by_zone_id: [ zone.id ])

        expect(summary.to_s).to eq('zone Downtown')
      end
    end

    describe 'geography' do
      it 'shows the state name(s) from by_state_name' do
        summary = described_class.new(by_state_name: [ 'OR' ])

        expect(summary.to_s).to eq('in OR')
      end

      it 'shows the state name(s) from by_state_id when by_state_name is absent' do
        summary = described_class.new(by_state_id: [ 'OR' ])

        expect(summary.to_s).to eq('in OR')
      end

      it 'shows the country' do
        summary = described_class.new(by_country: [ 'US' ])

        expect(summary.to_s).to eq('in US')
      end

      it 'combines state and country' do
        summary = described_class.new(by_state_name: [ 'OR' ], by_country: [ 'US' ])

        expect(summary.to_s).to eq('in OR, US')
      end
    end

    describe 'combining multiple categories' do
      it 'joins up to 3 active categories into one sentence' do
        bar = FactoryBot.create(:location_type, name: 'Bar')
        operator = FactoryBot.create(:operator, name: 'Quarterworld')

        summary = described_class.new(by_type_id: [ bar.id ], by_operator_id: [ operator.id ], by_is_stern_army: '1')

        expect(summary.to_s).to eq('location type Bar, Stern Army, and operator Quarterworld')
      end

      it 'collapses to "multiple filters" once more than 3 categories are active' do
        bar = FactoryBot.create(:location_type, name: 'Bar')
        operator = FactoryBot.create(:operator, name: 'Quarterworld')
        zone = FactoryBot.create(:zone, name: 'Downtown')

        summary = described_class.new(
          by_type_id: [ bar.id ],
          by_operator_id: [ operator.id ],
          by_zone_id: [ zone.id ],
          by_is_stern_army: '1'
        )

        expect(summary.to_s).to eq('multiple filters')
      end
    end
  end
end
