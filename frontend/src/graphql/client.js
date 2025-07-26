import { ApolloClient, InMemoryCache, createHttpLink } from '@apollo/client';

const httpLink = createHttpLink({
  uri: process.env.REACT_APP_GRAPHQL_URI || 'http://localhost:4000/graphql',
});

const client = new ApolloClient({
  link: httpLink,
  cache: new InMemoryCache({
    typePolicies: {
      Medicine: {
        fields: {
          isLowStock: {
            read(_, { readField }) {
              const stockQuantity = readField('stockQuantity');
              const minStockLevel = readField('minStockLevel');
              return stockQuantity <= minStockLevel;
            }
          },
          isExpired: {
            read(_, { readField }) {
              const expiryDate = readField('expiryDate');
              return new Date() > new Date(expiryDate);
            }
          },
          isExpiringSoon: {
            read(_, { readField }) {
              const expiryDate = readField('expiryDate');
              const thirtyDaysFromNow = new Date();
              thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);
              return new Date(expiryDate) <= thirtyDaysFromNow && new Date(expiryDate) > new Date();
            }
          }
        }
      }
    }
  }),
  defaultOptions: {
    watchQuery: {
      errorPolicy: 'all'
    },
    query: {
      errorPolicy: 'all'
    }
  }
});

export default client;
