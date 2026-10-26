import { shallowMount, flushPromises } from '@vue/test-utils';
import { createStore } from 'vuex';
import AddAgent from './AddAgent.vue';
import EditAgent from './EditAgent.vue';

vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));

describe('native agent roles after custom role configuration retirement', () => {
  let dispatch;
  let store;

  beforeEach(() => {
    store = createStore({ getters: { 'agents/getUIFlags': () => ({}) } });
    dispatch = vi.spyOn(store, 'dispatch').mockResolvedValue({});
  });

  it('offers only the two native roles when adding an agent and submits the selected role', async () => {
    const wrapper = shallowMount(AddAgent, { global: { plugins: [store] } });
    expect(
      wrapper.findAll('option').map(option => option.element.value)
    ).toEqual(['administrator', 'agent']);

    const inputs = wrapper.findAll('input');
    await inputs[0].setValue('New HR');
    await inputs[1].setValue('new-hr@example.test');
    await wrapper.find('form').trigger('submit');
    await flushPromises();

    expect(dispatch).toHaveBeenCalledWith('agents/create', {
      name: 'New HR',
      email: 'new-hr@example.test',
      role: 'agent',
    });
    wrapper.unmount();
  });

  it('keeps native role edits available without sending a custom role clearing parameter', async () => {
    const wrapper = shallowMount(EditAgent, {
      props: { id: 5, name: 'HR', type: 'agent', availability: 'online' },
      global: { plugins: [store] },
    });
    const select = wrapper.findAll('select')[0];
    expect(
      select.findAll('option').map(option => option.element.value)
    ).toEqual(['administrator', 'agent']);
    await select.setValue('administrator');
    await wrapper.find('form').trigger('submit');
    await flushPromises();

    expect(dispatch).toHaveBeenCalledWith('agents/update', {
      id: 5,
      name: 'HR',
      availability: 'online',
      role: 'administrator',
    });
    wrapper.unmount();
  });

  it('preserves historical permissions when editing the profile of an agent with a custom role', async () => {
    const wrapper = shallowMount(EditAgent, {
      props: {
        id: 5,
        name: 'HR',
        type: 'agent',
        availability: 'online',
        customRoleId: 7,
      },
      global: { plugins: [store] },
    });
    expect(wrapper.findAll('select')).toHaveLength(1);
    expect(wrapper.text()).toContain('CUSTOM_ROLE.HEADER');
    await wrapper.find('input').setValue('Updated HR');
    await wrapper.find('form').trigger('submit');
    await flushPromises();

    expect(dispatch).toHaveBeenCalledWith('agents/update', {
      id: 5,
      name: 'Updated HR',
      availability: 'online',
    });
    wrapper.unmount();
  });
});
