import { shallowMount } from '@vue/test-utils';
import ConversationFilter from './ConversationFilter.vue';
import ConditionRow from './ConditionRow.vue';
import filterQueryGenerator from 'dashboard/helper/filterQueryGenerator';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';

vi.mock('./provider.js', () => ({
  useConversationFilterContext: () => ({ attributeFilterTypes: [] }),
}));
vi.mock('dashboard/composables', () => ({ useTrack: vi.fn() }));
vi.mock('dashboard/composables/store', () => ({
  useStore: () => ({ dispatch: vi.fn() }),
}));

const validate = vi.fn();
const stubs = {
  Button: { template: '<button><slot /></button>' },
  Input: true,
  ConditionRow: {
    props: [
      'attributeKey',
      'filterOperator',
      'values',
      'filterTypes',
      'queryOperator',
      'showQueryOperator',
    ],
    template: '<li />',
    methods: { validate: () => validate() },
  },
};

describe('legacy campaign conditions', () => {
  beforeEach(() => validate.mockReturnValue(true));

  it.each([
    ['equal_to', [42, 57]],
    ['not_equal_to', ['001', 57]],
    ['is_present', []],
    ['is_not_present', []],
  ])(
    'saves a folder containing only a legacy %s condition unchanged',
    async (operator, values) => {
      const filters = [
        {
          attributeKey: 'campaign_id',
          filterOperator: operator,
          values,
          queryOperator: null,
        },
      ];
      const wrapper = shallowMount(ConversationFilter, {
        props: {
          modelValue: filters,
          isFolderView: true,
          folderName: 'Historical conversations',
        },
        global: { stubs },
      });

      expect(wrapper.findComponent(ConditionRow).exists()).toBe(false);
      expect(wrapper.text()).toContain(`FILTER.OPERATOR_LABELS.${operator}`);
      await wrapper.findAll('button').at(-1).trigger('click');

      expect(wrapper.emitted('updateFolder')).toEqual([
        [filters, 'Historical conversations'],
      ]);
      expect(validate).not.toHaveBeenCalled();
      expect(filters[0].values).toEqual(values);
      wrapper.unmount();
    }
  );

  it('preserves campaign IDs, AND/OR and ordering while saving other conditions', async () => {
    const filters = [
      {
        attributeKey: 'status',
        filterOperator: 'equal_to',
        values: [{ id: 'open', name: 'Open' }],
        queryOperator: 'and',
      },
      {
        attributeKey: 'campaign_id',
        filterOperator: 'not_equal_to',
        values: [42, 57],
        queryOperator: 'or',
      },
      {
        attributeKey: 'team_id',
        filterOperator: 'equal_to',
        values: { id: 7, name: 'HR' },
        queryOperator: null,
      },
    ];
    const wrapper = shallowMount(ConversationFilter, {
      props: {
        modelValue: filters,
        isFolderView: true,
        folderName: 'HR conversations',
      },
      global: { stubs },
    });

    expect(wrapper.findAllComponents(ConditionRow)).toHaveLength(2);
    expect(wrapper.text()).toContain('42, 57');
    await wrapper.findAll('button').at(-1).trigger('click');

    const [submittedFilters] = wrapper.emitted('updateFolder')[0];
    expect(filterQueryGenerator(useSnakeCase(submittedFilters))).toEqual({
      payload: [
        {
          attribute_key: 'status',
          filter_operator: 'equal_to',
          values: ['open'],
          query_operator: 'and',
        },
        {
          attribute_key: 'campaign_id',
          filter_operator: 'not_equal_to',
          values: [42, 57],
          query_operator: 'or',
        },
        {
          attribute_key: 'team_id',
          filter_operator: 'equal_to',
          values: [7],
          query_operator: undefined,
        },
      ],
    });
    expect(filters[1]).toEqual({
      attributeKey: 'campaign_id',
      filterOperator: 'not_equal_to',
      values: [42, 57],
      queryOperator: 'or',
    });
    wrapper.unmount();
  });

  it('continues validating editable conditions before saving a legacy folder', async () => {
    validate.mockReturnValue(false);
    const wrapper = shallowMount(ConversationFilter, {
      props: {
        modelValue: [
          {
            attributeKey: 'campaign_id',
            filterOperator: 'is_present',
            values: [],
            queryOperator: 'and',
          },
          {
            attributeKey: 'team_id',
            filterOperator: 'equal_to',
            values: [],
            queryOperator: null,
          },
        ],
        isFolderView: true,
        folderName: 'HR conversations',
      },
      global: { stubs },
    });

    await wrapper.findAll('button').at(-1).trigger('click');

    expect(validate).toHaveBeenCalledOnce();
    expect(wrapper.emitted('updateFolder')).toBeUndefined();
    wrapper.unmount();
  });
});
