import defaultFilters from '../index';
import { filterAttributeGroups } from '../index';

describe('#filterItems', () => {
  it('does not expose campaigns in new filter choices or groups', () => {
    expect(
      defaultFilters.some(filter => filter.attributeKey === 'campaign_id')
    ).toBe(false);
    expect(
      filterAttributeGroups
        .flatMap(group => group.attributes)
        .some(attribute => attribute.key === 'campaign_id')
    ).toBe(false);
  });

  it('Matches the correct filterItems', () => {
    expect(defaultFilters).toMatchObject(defaultFilters);
    expect(filterAttributeGroups).toMatchObject(filterAttributeGroups);
  });
});
