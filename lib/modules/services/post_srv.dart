import 'base_graphql.dart';

class PostSrv extends BaseService {
  PostSrv() : super(module: 'Post', fragment: ''' 
id
content
mediaPostIds
commentIds
userId
like
userLikeIds
share
userShareIds
locationLat
locationLong
expirationDate
publicity
user {
  id 
  uid 
  name 
  email 
  phone 
  role 
  reputationScore 
  createdAt 
  updatedAt 
  friendIds
}
mediaPosts {
id
userId
type
like
userLikeIds
commentIds
description
url
locationLat
locationLong
expirationDate
publicity
createdAt
updatedAt
}
createdAt
updatedAt
  ''');
}

class MediaPostSrv extends BaseService {
  MediaPostSrv() : super(module: 'MediaPost', fragment: ''' 
id
userId
type
like
userLikeIds
commentIds
description
url
locationLat
locationLong
expirationDate
publicity
createdAt
updatedAt
}
createdAt
updatedAt
  ''');
}