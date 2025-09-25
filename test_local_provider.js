// 简单测试LocalProvider功能
const { LocalProvider } = require('./Application/entry/src/main/ets/common/localProvider');

// 测试搜索功能
async function testLocalProvider() {
  try {
    const provider = new LocalProvider();
    
    // 测试搜索附近厕所
    const searchOptions = {
      center: { lat: 39.9042, lng: 116.4074 }, // 北京天安门
      radiusM: 5000, // 5公里半径
      limit: 10
    };
    
    console.log('Testing LocalProvider.searchToilets...');
    const toilets = await provider.searchToilets(searchOptions);
    console.log(`Found ${toilets.length} toilets:`);
    
    toilets.forEach((toilet, index) => {
      console.log(`${index + 1}. ${toilet.name} - ${toilet.address}`);
    });
    
    // 测试获取所有厕所
    console.log('\nTesting LocalProvider.getAllToilets...');
    const allToilets = await provider.getAllToilets();
    console.log(`Total toilets in database: ${allToilets.length}`);
    
  } catch (error) {
    console.error('Test failed:', error);
  }
}

testLocalProvider();